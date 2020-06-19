/* global ace */

import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { BLOB_EDITOR_ERROR, BLOB_PREVIEW_ERROR } from './constants';
import TemplateSelectorMediator from '../blob/file_template_mediator';
import getModeByFileExtension from '~/lib/utils/ace_utils';
import { addEditorMarkdownListeners } from '~/lib/utils/text_markdown';

const monacoEnabled = window?.gon?.features?.monacoBlobs;

export default class EditBlob {
  // The options object has:
  // assetsPath, filePath, currentAction, projectId, isMarkdown
  constructor(options) {
    this.options = options;
    const { isMarkdown } = this.options;
    Promise.resolve()
      .then(() => {
        return monacoEnabled ? this.configureMonacoEditor() : this.configureAceEditor();
      })
      .then(() => {
        this.initModePanesAndLinks();
        this.initFileSelectors();
        this.initSoftWrap();
        if (isMarkdown) {
          addEditorMarkdownListeners(this.editor);
        }
        this.editor.focus();
      })
      .catch(() => createFlash(BLOB_EDITOR_ERROR));
  }

  configureMonacoEditor() {
    return import(/* webpackChunkName: 'monaco_editor_lite' */ '~/editor/editor_lite').then(
      EditorModule => {
        const EditorLite = EditorModule.default;
        const editorEl = document.getElementById('editor');
        const fileNameEl =
          document.getElementById('file_path') || document.getElementById('file_name');
        const fileContentEl = document.getElementById('file-content');
        const form = document.querySelector('.js-edit-blob-form');

        this.editor = new EditorLite();

        this.editor.createInstance({
          el: editorEl,
          blobPath: fileNameEl.value,
          blobContent: editorEl.innerText,
        });

        fileNameEl.addEventListener('change', () => {
          this.editor.updateModelLanguage(fileNameEl.value);
        });

        form.addEventListener('submit', () => {
          fileContentEl.value = this.editor.getValue();
        });
      },
    );
  }

  configureAceEditor() {
    const { filePath, assetsPath } = this.options;
    ace.config.set('modePath', `${assetsPath}/ace`);
    ace.config.loadModule('ace/ext/searchbox');
    ace.config.loadModule('ace/ext/modelist');

    this.editor = ace.edit('editor');

    // This prevents warnings re: automatic scrolling being logged
    this.editor.$blockScrolling = Infinity;

    if (filePath) {
      this.editor.getSession().setMode(getModeByFileExtension(filePath));
    }
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
    this.isSoftWrapped = Boolean(monacoEnabled);
    this.$toggleButton = $('.soft-wrap-toggle');
    this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
    this.$toggleButton.on('click', () => this.toggleSoftWrap());
  }

  toggleSoftWrap() {
    this.isSoftWrapped = !this.isSoftWrapped;
    this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
    if (monacoEnabled) {
      this.editor.updateOptions({ wordWrap: this.isSoftWrapped ? 'on' : 'off' });
    } else {
      this.editor.getSession().setUseWrapMode(this.isSoftWrapped);
    }
  }
}
