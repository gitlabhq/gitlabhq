import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { BLOB_EDITOR_ERROR, BLOB_PREVIEW_ERROR } from './constants';
import TemplateSelectorMediator from '../blob/file_template_mediator';
import { addEditorMarkdownListeners } from '~/lib/utils/text_markdown';
import EditorLite from '~/editor/editor_lite';
import FileTemplateExtension from '~/editor/editor_file_template_ext';

export default class EditBlob {
  // The options object has:
  // assetsPath, filePath, currentAction, projectId, isMarkdown
  constructor(options) {
    this.options = options;
    this.configureMonacoEditor();

    if (this.options.isMarkdown) {
      import('~/editor/editor_markdown_ext')
        .then(MarkdownExtension => {
          this.editor.use(MarkdownExtension.default);
          addEditorMarkdownListeners(this.editor);
        })
        .catch(() => createFlash(BLOB_EDITOR_ERROR));
    }

    this.initModePanesAndLinks();
    this.initFileSelectors();
    this.initSoftWrap();
    this.editor.focus();
  }

  configureMonacoEditor() {
    const editorEl = document.getElementById('editor');
    const fileNameEl = document.getElementById('file_path') || document.getElementById('file_name');
    const fileContentEl = document.getElementById('file-content');
    const form = document.querySelector('.js-edit-blob-form');

    const rootEditor = new EditorLite();

    this.editor = rootEditor.createInstance({
      el: editorEl,
      blobPath: fileNameEl.value,
      blobContent: editorEl.innerText,
    });
    this.editor.use(FileTemplateExtension);

    fileNameEl.addEventListener('change', () => {
      this.editor.updateModelLanguage(fileNameEl.value);
    });

    form.addEventListener('submit', () => {
      fileContentEl.value = this.editor.getValue();
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
    this.$editModeLinks.on('click', e => this.editModeLinkClickHandler(e));
  }

  editModeLinkClickHandler(e) {
    e.preventDefault();

    const currentLink = $(e.target);
    const paneId = currentLink.attr('href');
    const currentPane = this.$editModePanes.filter(paneId);

    this.$editModeLinks.parent().removeClass('active hover');

    currentLink.parent().addClass('active hover');

    this.$editModePanes.hide();

    currentPane.fadeIn(200);

    if (paneId === '#preview') {
      this.$toggleButton.hide();
      axios
        .post(currentLink.data('previewUrl'), {
          content: this.editor.getValue(),
        })
        .then(({ data }) => {
          currentPane.empty().append(data);
          currentPane.renderGFM();
        })
        .catch(() => createFlash(BLOB_PREVIEW_ERROR));
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
