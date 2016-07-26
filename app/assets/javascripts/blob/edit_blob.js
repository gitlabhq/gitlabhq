(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.EditBlob = (function() {
    function EditBlob(assets_path, ace_mode) {
      if (ace_mode == null) {
        ace_mode = null;
      }
      this.editModeLinkClickHandler = bind(this.editModeLinkClickHandler, this);
      ace.config.set("modePath", assets_path + "/ace");
      ace.config.loadModule("ace/ext/searchbox");
      this.editor = ace.edit("editor");
      this.editor.focus();
      if (ace_mode) {
        this.editor.getSession().setMode("ace/mode/" + ace_mode);
      }
      $('form').submit((function(_this) {
        return function() {
          return $("#file-content").val(_this.editor.getValue());
        };
      })(this));
      this.initModePanesAndLinks();
      new BlobLicenseSelectors({
        editor: this.editor
      });
      new BlobGitignoreSelectors({
        editor: this.editor
      });
      new BlobCiYamlSelectors({
        editor: this.editor
      });
    }

    EditBlob.prototype.initModePanesAndLinks = function() {
      this.$editModePanes = $(".js-edit-mode-pane");
      this.$editModeLinks = $(".js-edit-mode a");
      return this.$editModeLinks.click(this.editModeLinkClickHandler);
    };

    EditBlob.prototype.editModeLinkClickHandler = function(event) {
      var currentLink, currentPane, paneId;
      event.preventDefault();
      currentLink = $(event.target);
      paneId = currentLink.attr("href");
      currentPane = this.$editModePanes.filter(paneId);
      this.$editModeLinks.parent().removeClass("active hover");
      currentLink.parent().addClass("active hover");
      this.$editModePanes.hide();
      currentPane.fadeIn(200);
      if (paneId === "#preview") {
        return $.post(currentLink.data("preview-url"), {
          content: this.editor.getValue()
        }, function(response) {
          currentPane.empty().append(response);
          return currentPane.syntaxHighlight();
        });
      } else {
        return this.editor.focus();
      }
    };

    return EditBlob;

  })();

}).call(this);
