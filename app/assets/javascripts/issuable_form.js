(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.IssuableForm = (function() {
    IssuableForm.prototype.issueMoveConfirmMsg = 'Are you sure you want to move this issue to another project?';

    IssuableForm.prototype.wipRegex = /^\s*(\[WIP\]\s*|WIP:\s*|WIP\s+)+\s*/i;

    function IssuableForm(form) {
      var $issuableDueDate;
      this.form = form;
      this.toggleWip = bind(this.toggleWip, this);
      this.renderWipExplanation = bind(this.renderWipExplanation, this);
      this.resetAutosave = bind(this.resetAutosave, this);
      this.handleSubmit = bind(this.handleSubmit, this);
      GitLab.GfmAutoComplete.setup();
      new UsersSelect();
      new GroupsSelect();
      new ZenMode();
      this.titleField = this.form.find("input[name*='[title]']");
      this.descriptionField = this.form.find("textarea[name*='[description]']");
      this.issueMoveField = this.form.find("#move_to_project_id");
      if (!(this.titleField.length && this.descriptionField.length)) {
        return;
      }
      this.initAutosave();
      this.form.on("submit", this.handleSubmit);
      this.form.on("click", ".btn-cancel", this.resetAutosave);
      this.initWip();
      this.initMoveDropdown();
      $issuableDueDate = $('#issuable-due-date');
      if ($issuableDueDate.length) {
        $('.datepicker').datepicker({
          dateFormat: 'yy-mm-dd',
          onSelect: function(dateText, inst) {
            return $issuableDueDate.val(dateText);
          }
        }).datepicker('setDate', $.datepicker.parseDate('yy-mm-dd', $issuableDueDate.val()));
      }
    }

    IssuableForm.prototype.initAutosave = function() {
      new Autosave(this.titleField, [document.location.pathname, document.location.search, "title"]);
      return new Autosave(this.descriptionField, [document.location.pathname, document.location.search, "description"]);
    };

    IssuableForm.prototype.handleSubmit = function() {
      var ref, ref1;
      if (((ref = parseInt((ref1 = this.issueMoveField) != null ? ref1.val() : void 0)) != null ? ref : 0) > 0) {
        if (!confirm(this.issueMoveConfirmMsg)) {
          return false;
        }
      }
      return this.resetAutosave();
    };

    IssuableForm.prototype.resetAutosave = function() {
      this.titleField.data("autosave").reset();
      return this.descriptionField.data("autosave").reset();
    };

    IssuableForm.prototype.initWip = function() {
      this.$wipExplanation = this.form.find(".js-wip-explanation");
      this.$noWipExplanation = this.form.find(".js-no-wip-explanation");
      if (!(this.$wipExplanation.length && this.$noWipExplanation.length)) {
        return;
      }
      this.form.on("click", ".js-toggle-wip", this.toggleWip);
      this.titleField.on("keyup blur", this.renderWipExplanation);
      return this.renderWipExplanation();
    };

    IssuableForm.prototype.workInProgress = function() {
      return this.wipRegex.test(this.titleField.val());
    };

    IssuableForm.prototype.renderWipExplanation = function() {
      if (this.workInProgress()) {
        this.$wipExplanation.show();
        return this.$noWipExplanation.hide();
      } else {
        this.$wipExplanation.hide();
        return this.$noWipExplanation.show();
      }
    };

    IssuableForm.prototype.toggleWip = function(event) {
      event.preventDefault();
      if (this.workInProgress()) {
        this.removeWip();
      } else {
        this.addWip();
      }
      return this.renderWipExplanation();
    };

    IssuableForm.prototype.removeWip = function() {
      return this.titleField.val(this.titleField.val().replace(this.wipRegex, ""));
    };

    IssuableForm.prototype.addWip = function() {
      return this.titleField.val("WIP: " + (this.titleField.val()));
    };

    IssuableForm.prototype.initMoveDropdown = function() {
      var $moveDropdown, pageSize;
      $moveDropdown = $('.js-move-dropdown');
      if ($moveDropdown.length) {
        pageSize = $moveDropdown.data('page-size');
        return $('.js-move-dropdown').select2({
          ajax: {
            url: $moveDropdown.data('projects-url'),
            quietMillis: 125,
            data: function(term, page, context) {
              return {
                search: term,
                offset_id: context
              };
            },
            results: function(data) {
              var context,
                more;

              if (data.length >= pageSize)
                more = true;

              if (data[data.length - 1])
                context = data[data.length - 1].id;

              return {
                results: data,
                more: more,
                context: context
              };
            }
          },
          formatResult: function(project) {
            return project.name_with_namespace;
          },
          formatSelection: function(project) {
            return project.name_with_namespace;
          }
        });
      }
    };

    return IssuableForm;

  })();

}).call(this);
