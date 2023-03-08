import $ from 'jquery';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { FileTemplateExtension } from '~/editor/extensions/source_editor_file_template_ext';
import { ToolbarExtension } from '~/editor/extensions/source_editor_toolbar_ext';
import SourceEditor from '~/editor/source_editor';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { addEditorMarkdownListeners } from '~/lib/utils/text_markdown';
import { insertFinalNewline } from '~/lib/utils/text_utility';
import TemplateSelectorMediator from '../blob/file_template_mediator';
import { BLOB_EDITOR_ERROR, BLOB_PREVIEW_ERROR } from './constants';

export default class EditBlob {
  // The options object has:
  // assetsPath, filePath, currentAction, projectId, isMarkdown, previewMarkdownPath
  constructor(options) {
    this.options = options;
    this.configureMonacoEditor();
    this.isMarkdown = this.options.isMarkdown;
    this.markdownLivePreviewOpened = false;

    if (this.isMarkdown) {
      this.fetchMarkdownExtension();
    }

    this.initModePanesAndLinks();
    this.initFileSelectors();
    this.initSoftWrap();
    this.editor.focus();
  }

  async fetchMarkdownExtension() {
    try {
      const [
        { EditorMarkdownExtension: MarkdownExtension },
        { EditorMarkdownPreviewExtension: MarkdownLivePreview },
      ] = await Promise.all([
        import('~/editor/extensions/source_editor_markdown_ext'),
        import('~/editor/extensions/source_editor_markdown_livepreview_ext'),
      ]);
      this.markdownExtensions = this.editor.use([
        { definition: MarkdownExtension },
        {
          definition: MarkdownLivePreview,
          setupOptions: { previewMarkdownPath: this.options.previewMarkdownPath },
        },
      ]);
    } catch (e) {
      createAlert({
        message: `${BLOB_EDITOR_ERROR}: ${e}`,
      });
    }
    addEditorMarkdownListeners(this.editor);
  }

  configureMonacoEditor() {
    const editorEl = document.getElementById('editor');
    const fileNameEl = document.getElementById('file_path') || document.getElementById('file_name');
    const fileContentEl = document.getElementById('file-content');
    const form = document.querySelector('.js-edit-blob-form');

    const rootEditor = new SourceEditor();

    this.editor = rootEditor.createInstance({
      el: editorEl,
      blobPath: fileNameEl.value,
      blobContent: editorEl.innerText,
    });
    this.editor.use([
      { definition: ToolbarExtension },
      { definition: SourceEditorExtension },
      { definition: FileTemplateExtension },
    ]);

    fileNameEl.addEventListener('change', () => {
      this.editor.updateModelLanguage(fileNameEl.value);
    });

    form.addEventListener('submit', () => {
      fileContentEl.value = insertFinalNewline(this.editor.getValue());
    });

    // onDidChangeModelLanguage is part of the native Monaco API
    // https://microsoft.github.io/monaco-editor/api/interfaces/monaco.editor.IStandaloneCodeEditor.html#onDidChangeModelLanguage
    this.editor.onDidChangeModelLanguage(({ newLanguage = '', oldLanguage = '' }) => {
      if (newLanguage === 'markdown') {
        this.fetchMarkdownExtension();
      } else if (oldLanguage === 'markdown') {
        this.editor.unuse(this.markdownExtensions);
      }
    });
  }

  initFileSelectors() {
    const { currentAction, projectId } = this.options;
    this.fileTemplateMediator = new TemplateSelectorMediator({
      currentAction,
      editor: this.editor,
      projectId,
    });
  }

  initModePanesAndLinks() {
    this.$editModePanes = $('.js-edit-mode-pane');
    this.$editModeLinks = $('.js-edit-mode a');
    this.$editModeLinks.on('click', (e) => this.editModeLinkClickHandler(e));
  }

  toggleMarkdownPreview(toOpen) {
    if (toOpen !== this.markdownLivePreviewOpened) {
      this.editor.markdownPreview?.eventEmitter.fire();
      this.markdownLivePreviewOpened = !this.markdownLivePreviewOpened;
    }
  }

  editModeLinkClickHandler(e) {
    e.preventDefault();

    const currentLink = $(e.target);
    const paneId = currentLink.attr('href');
    const currentPane = this.$editModePanes.filter(paneId);

    this.$editModeLinks.parent().removeClass('active hover');

    currentLink.parent().addClass('active hover');

    if (this.isMarkdown) {
      this.toggleMarkdownPreview(paneId === '#preview');
    } else {
      this.$editModePanes.hide();

      currentPane.show();

      if (paneId === '#preview') {
        this.$toggleButton.hide();
        axios
          .post(currentLink.data('previewUrl'), {
            content: this.editor.getValue(),
          })
          .then(({ data }) => {
            currentPane.empty().append(data);
            renderGFM(currentPane.get(0));
          })
          .catch(() =>
            createAlert({
              message: BLOB_PREVIEW_ERROR,
            }),
          );
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
}
