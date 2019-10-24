/* global ace */

import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { blobLinkRegex } from '~/blob/blob_utils';
import TemplateSelectorMediator from '~/blob/file_template_mediator';
import getModeByFileExtension from '~/lib/utils/ace_utils';
import { addEditorMarkdownListeners } from '~/lib/utils/text_markdown';

export default class EditBlob {
  // The options object has:
  // assetsPath, filePath, currentAction, projectId, isMarkdown
  constructor(options) {
    this.options = options;
    this.configureAceEditor();
    this.initModePanesAndLinks();
    this.initSoftWrap();
    this.initFileSelectors();
    this.initBlobContentLinkClickability();
  }

  configureAceEditor() {
    const { filePath, assetsPath, isMarkdown } = this.options;
    ace.config.set('modePath', `${assetsPath}/ace`);
    ace.config.loadModule('ace/ext/searchbox');
    ace.config.loadModule('ace/ext/modelist');

    this.editor = ace.edit('editor');

    if (isMarkdown) {
      addEditorMarkdownListeners(this.editor);
    }

    // This prevents warnings re: automatic scrolling being logged
    this.editor.$blockScrolling = Infinity;

    this.editor.focus();

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
        .catch(() => createFlash(__('An error occurred previewing the blob')));
    }

    this.$toggleButton.show();

    return this.editor.focus();
  }

  initBlobContentLinkClickability() {
    this.editor.renderer.on('afterRender', () => {
      document.querySelectorAll('.ace_text-layer .ace_line > *').forEach(token => {
        if (token.dataset.linkified || !token.textContent.includes('http')) return;

        // eslint-disable-next-line no-param-reassign
        token.innerHTML = token.innerHTML.replace(
          blobLinkRegex,
          '<a target="_blank" href="$&">$&</a>',
        );
        // eslint-disable-next-line no-param-reassign
        token.dataset.linkified = true;
      });
    });
  }

  initSoftWrap() {
    this.isSoftWrapped = false;
    this.$toggleButton = $('.soft-wrap-toggle');
    this.$toggleButton.on('click', () => this.toggleSoftWrap());
  }

  toggleSoftWrap() {
    this.isSoftWrapped = !this.isSoftWrapped;
    this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
    this.editor.getSession().setUseWrapMode(this.isSoftWrapped);
  }
}
