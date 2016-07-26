((global) => {
  class EditBlob {
    constructor(assetsPath, aceMode = null) {
      ace.config.set('modePath', `${assetsPath}/ace`);
      ace.config.loadModule('ace/ext/searchbox');

      this.editor = ace.edit('editor');
      this.editor.focus();
      if (aceMode) this.editor.getSession().setMode(`ace/mode/${aceMode}`);

      $('form').submit(() => {
        $('#file-content').val(this.editor.getValue());
      });

      this.initModePanesAndLinks();

      new BlobLicenseSelectors({ editor: this.editor });
      new BlobGitignoreSelectors({ editor: this.editor });
      new BlobCiYamlSelectors({ editor: this.editor });
    }

    initModePanesAndLinks() {
      this.$editModePanes = $('.js-edit-mode-pane');
      this.$editModeLinks = $('.js-edit-mode a');
      this.$editModeLinks.click((e) => this.editModeLinkClickHandler(e));
    }

    editModeLinkClickHandler(event) {
      event.preventDefault();
      let $currentLink = $(event.target);
      let paneId = $currentLink.attr('href');
      let currentPane = this.$editModePanes.filter(paneId);
      this.$editModeLinks.parent().removeClass('active hover');
      $currentLink.parent().addClass('active hover');
      this.$editModePanes.hide();
      currentPane.fadeIn(200);
      if (paneId === '#preview') {
        $.post($currentLink.data('preview-url'), {
          content: this.editor.getValue()
        }, (response) => {
          currentPane.empty().append(response).syntaxHighlight();
        });
      } else {
        this.editor.focus();
      }
    }
  }

  global.EditBlob = EditBlob;
})(window);
