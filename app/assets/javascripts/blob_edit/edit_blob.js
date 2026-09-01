import $ from 'jquery';
import { __ } from '~/locale';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { FileTemplateExtension } from '~/editor/extensions/source_editor_file_template_ext';
import { ToolbarExtension } from '~/editor/extensions/source_editor_toolbar_ext';
import SourceEditor from '~/editor/source_editor';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { addEditorMarkdownListeners } from '~/lib/utils/text_markdown';
import FilepathFormMediator from '~/blob/filepath_form_mediator';
import mountFilepathForm from '~/blob/filepath_form';
import { HTTP_STATUS_PAYLOAD_TOO_LARGE } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import Api from '~/api';
import { createDynamicHeightManager } from '~/vue_shared/utils/dynamic_height';

import { BLOB_EDITOR_ERROR, BLOB_PREVIEW_ERROR, BLOB_EDIT_ERROR } from './constants';

const findFileNameEl = () =>
  document.getElementById('file_path') || document.getElementById('file_name');

export default class EditBlob {
  // The options object has:
  // assetsPath, filePath, currentAction, projectId, isMarkdown, previewMarkdownPath
  constructor(options) {
    this.options = options;
    this.configureMonacoEditor();

    this.initModePanesAndLinks();
    this.initSoftWrap();
  }

  installMarkdownExtensions() {
    this.markdownExtensionsPromise ??= this.loadMarkdownExtensions();
    return this.markdownExtensionsPromise;
  }

  uninstallMarkdownExtensions() {
    if (this.markdownExtensions) {
      this.editor.unuse(this.markdownExtensions);
      this.markdownExtensions = null;
    }
    this.markdownExtensionsPromise = null;
  }

  async loadMarkdownExtensions() {
    try {
      const [
        { EditorMarkdownExtension: MarkdownExtension },
        { EditorMarkdownPreviewExtension: MarkdownLivePreview },
      ] = await Promise.all([
        import('~/editor/extensions/source_editor_markdown_ext'),
        import('~/editor/extensions/source_editor_markdown_livepreview_ext'),
      ]);

      // The file may have been renamed away from markdown
      // while the extensions were loading (cache cleared),
      // or renamed back so that another load has already installed them.
      if (!this.markdownExtensionsPromise || this.markdownExtensions) {
        return;
      }

      this.markdownExtensions = this.editor.use([
        { definition: MarkdownExtension },
        {
          definition: MarkdownLivePreview,
          setupOptions: { previewMarkdownPath: this.options.previewMarkdownPath },
        },
      ]);
      addEditorMarkdownListeners(this.editor);
    } catch (e) {
      // No load identity check: the promise seen here is not from a load that
      // could still succeed. Loads of the same chunks share one in-flight request
      // and fail together, and this rejection handler (microtask) runs before
      // any rename event (macrotask) can start a newer load.
      if (this.markdownExtensionsPromise) {
        createAlert({ message: BLOB_EDITOR_ERROR, error: e, captureError: true });
        this.markdownExtensionsPromise = null;
      }
    }
  }

  async fetchSecurityPolicyExtension(projectPath) {
    try {
      const { SecurityPolicySchemaExtension } =
        await import('~/editor/extensions/source_editor_security_policy_schema_ext');
      this.editor.use([{ definition: SecurityPolicySchemaExtension }]);
      this.editor.registerSecurityPolicySchema(projectPath);
    } catch (e) {
      createAlert({
        message: `${BLOB_EDITOR_ERROR}: ${e}`,
      });
    }
  }

  async configureMonacoEditor() {
    const editorEl = document.getElementById('editor');
    const form = document.querySelector('.js-edit-blob-form');

    const rootEditor = new SourceEditor();
    const { filePath, projectId } = this.options;
    const { ref } = editorEl.dataset;
    let blobContent = '';
    const preEl = editorEl.querySelector('.editor-loading-content');

    if (filePath) {
      const { data } = await Api.getRawFile(
        projectId,
        filePath,
        { ref },
        { responseType: 'text', transformResponse: (x) => x },
      );
      blobContent = String(data);
    } else if (preEl && preEl.textContent) {
      blobContent = preEl.textContent;
    }

    this.editor = rootEditor.createInstance({
      el: editorEl,
      blobContent,
      blobPath: this.options.filePath,
    });
    this.editor.use([
      { definition: ToolbarExtension },
      { definition: SourceEditorExtension },
      { definition: FileTemplateExtension },
    ]);

    if (this.options.isMarkdown) {
      this.installMarkdownExtensions();
    }

    if (this.options.filePath === '.gitlab/security-policies/policy.yml') {
      await this.fetchSecurityPolicyExtension(this.options.projectPath);
    }

    this.initFilepathForm();
    this.initDynamicHeight();
    this.editor.focus();

    form.addEventListener('submit', async (event) => {
      event.preventDefault();

      const { formMethod } = form.dataset;
      const endpoint = form.action;
      const formData = new FormData(form);
      formData.set('content', this.editor.getValue());

      try {
        const { data } = await axios[formMethod](endpoint, Object.fromEntries(formData));
        visitUrl(data.filePath);
      } catch (error) {
        createAlert({ message: BLOB_EDIT_ERROR, captureError: true });
      }
    });

    // onDidChangeModelLanguage is part of the native Monaco API
    // https://microsoft.github.io/monaco-editor/api/interfaces/monaco.editor.IStandaloneCodeEditor.html#onDidChangeModelLanguage
    this.editor.onDidChangeModelLanguage(({ newLanguage = '', oldLanguage = '' }) => {
      if (newLanguage === 'markdown') {
        this.installMarkdownExtensions();
      } else if (oldLanguage === 'markdown') {
        this.uninstallMarkdownExtensions();
      }
    });
  }

  initDynamicHeight() {
    const editorElement = document.getElementById('editor');
    this.dynamicHeightManager = createDynamicHeightManager(editorElement);
  }

  destroy() {
    if (this.dynamicHeightManager) {
      this.dynamicHeightManager.destroy();
      this.dynamicHeightManager = null;
    }
  }

  initFilepathForm() {
    const { currentAction, projectId } = this.options;
    this.filepathFormMediator = new FilepathFormMediator({
      currentAction,
      editor: this.editor,
      projectId,
      // Injected rather than imported by the mediator. The Vue 3 build picks which files to
      // convert by following imports out from the page entry and does not trace through the
      // mediator, so importing the form there would leave it on Vue 2. Keep the import here.
      mountFilepathForm,
    });
    this.initFilepathListeners();
  }

  initFilepathListeners() {
    const fileNameEl = findFileNameEl();
    this.editor.updateModelLanguage(fileNameEl.value);
    fileNameEl.addEventListener('input', () => {
      this.editor.updateModelLanguage(fileNameEl.value);
    });
  }

  initModePanesAndLinks() {
    this.$editModePanes = $('.js-edit-mode-pane');
    this.$editModeLinks = $('.js-edit-mode a');
    this.$editModeLinks.on('click', (e) => this.editModeLinkClickHandler(e));
  }

  toggleMarkdownPreview(toOpen) {
    const preview = this.editor.markdownPreview;
    if (preview && toOpen !== preview.shown) {
      preview.eventEmitter.fire();
    }
  }

  static createBlobAlert = (error) => {
    if (error.response.status === HTTP_STATUS_PAYLOAD_TOO_LARGE) {
      createAlert({
        message: __('The blob is too large to render'),
      });
    } else {
      createAlert({
        message: BLOB_PREVIEW_ERROR,
      });
    }
  };

  editModeLinkClickHandler(e) {
    e.preventDefault();

    const currentLink = $(e.target);
    const paneId = currentLink.attr('href');
    const currentPane = this.$editModePanes.filter(paneId);

    this.$editModeLinks.parent().removeClass('active hover');

    currentLink.parent().addClass('active hover');

    this.$editModePanes.hide();

    if (this.markdownExtensions) {
      // The live preview renders next to the editor, so the editor pane
      // is always the one to show, even if the preview pane was open.
      this.$editModePanes.filter('#editor').show();
      this.toggleMarkdownPreview(paneId === '#preview');
    } else {
      currentPane.show();

      if (paneId === '#preview') {
        this.$toggleButton.hide();
        axios
          .post(currentLink.data('previewUrl'), {
            content: this.editor.getValue(),
            file_path: findFileNameEl()?.value,
          })
          .then(({ data }) => {
            currentPane.empty().append(data);
            renderGFM(currentPane.get(0));
          })
          .catch((error) => {
            EditBlob.createBlobAlert(error);
          });
      }
    }

    this.$toggleButton.show();

    return this.editor.focus();
  }

  initSoftWrap() {
    this.isSoftWrapped = true;
    this.$toggleButton = $('.soft-wrap-toggle');
    this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
    this.$toggleButton.on('click', () => this.toggleSoftWrap());
  }

  toggleSoftWrap() {
    this.isSoftWrapped = !this.isSoftWrapped;
    this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
    this.editor.updateOptions({ wordWrap: this.isSoftWrapped ? 'on' : 'off' });
  }

  getFileContent() {
    return this.editor?.getValue();
  }

  getOriginalFilePath() {
    return this.options.filePath;
  }
}
