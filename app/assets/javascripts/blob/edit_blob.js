/* eslint-disable no-new */
/* global ace */

import BlobCiYamlSelectors from './template_selectors/blob_ci_yaml_selectors';
import BlobDockerfileSelectors from './template_selectors/blob_dockerfile_selectors';
import BlobGitignoreSelectors from './template_selectors/blob_gitignore_selectors';
import BlobLicenseSelectors from './template_selectors/blob_license_selectors';

export default class EditBlob {
  constructor(assetsPath, aceMode) {
    this.editModeLinkClickHandler = this.editModeLinkClickHandler.bind(this);
    ace.config.set('modePath', `${assetsPath}/ace`);
    ace.config.loadModule('ace/ext/searchbox');
    this.editor = ace.edit('editor');
    this.editor.focus();
    if (aceMode) {
      this.editor.getSession().setMode(`ace/mode/${aceMode}`);
    }

    // Before a form submission, move the content from the Ace editor into the
    // submitted textarea
    $('form').submit(() => $('#file-content').val(this.editor.getValue()));

    this.initModePanesAndLinks();
    this.initSoftWrap();

    new BlobLicenseSelectors({ editor: this.editor });
    new BlobGitignoreSelectors({ editor: this.editor });
    new BlobCiYamlSelectors({ editor: this.editor });
    new BlobDockerfileSelectors({ editor: this.editor });
  }

  initModePanesAndLinks() {
    this.$editModePanes = $('.js-edit-mode-pane');
    this.$editModeLinks = $('.js-edit-mode a');
    this.$editModeLinks.click(this.editModeLinkClickHandler);
  }

  editModeLinkClickHandler(event) {
    event.preventDefault();
    const currentLink = $(event.target);
    const paneId = currentLink.attr('href');
    const currentPane = this.$editModePanes.filter(paneId);
    this.$editModeLinks.parent().removeClass('active hover');
    currentLink.parent().addClass('active hover');
    this.$editModePanes.hide();
    currentPane.fadeIn(200);
    if (paneId === '#preview') {
      this.$toggleButton.hide();
      $.post(currentLink.data('preview-url'), {
        content: this.editor.getValue(),
      }, (response) => {
        currentPane.empty().append(response);
        currentPane.renderGFM();
      });
    } else {
      this.$toggleButton.show();
      this.editor.focus();
    }
  }

  initSoftWrap() {
    this.isSoftWrapped = false;
    this.$toggleButton = $('.soft-wrap-toggle');
    this.$toggleButton.on('click', this.toggleSoftWrap.bind(this));
  }

  toggleSoftWrap() {
    this.isSoftWrapped = !this.isSoftWrapped;
    this.$toggleButton.toggleClass('soft-wrap-active', this.isSoftWrapped);
    this.editor.getSession().setUseWrapMode(this.isSoftWrapped);
  }
}
