/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, comma-dangle, prefer-template, quotes, no-param-reassign, wrap-iife, max-len */
/* global Api */

(function (w) {
  class CreateLabelDropdown {
    constructor ($el, namespacePath, projectPath) {
      this.$el = $el;
      this.namespacePath = namespacePath;
      this.projectPath = projectPath;
      this.$dropdownBack = $('.dropdown-menu-back', this.$el.closest('.dropdown'));
      this.$cancelButton = $('.js-cancel-label-btn', this.$el);
      this.$newLabelField = $('#new_label_name', this.$el);
      this.$newColorField = $('#new_label_color', this.$el);
      this.$colorPreview = $('.js-dropdown-label-color-preview', this.$el);
      this.$newLabelError = $('.js-label-error', this.$el);
      this.$newLabelCreateButton = $('.js-new-label-btn', this.$el);
      this.$colorSuggestions = $('.suggest-colors-dropdown a', this.$el);

      this.$newLabelError.hide();
      this.$newLabelCreateButton.disable();

      this.cleanBinding();
      this.addBinding();
    }

    cleanBinding () {
      this.$colorSuggestions.off('click.addColorValue');
      this.$newLabelField.off('keyup.enableLabelCreateButton change.enableLabelCreateButton');
      this.$newColorField.off('keyup.enableLabelCreateButton change.enableLabelCreateButton');
      this.$dropdownBack.off('click.resetForm');
      this.$cancelButton.off('click.cancelForm');
      this.$newLabelCreateButton.off('click.saveLabel');
    }

    addBinding () {
      const self = this;

      this.$colorSuggestions.off('click.addColorValue').on('click.addColorValue', function (e) {
        const $this = $(this);
        self.addColorValue(e, $this);
      });

      this.$newLabelField
        .off('keyup.enableLabelCreateButton change.enableLabelCreateButton')
        .on('keyup.enableLabelCreateButton change.enableLabelCreateButton', this.enableLabelCreateButton.bind(this));
      this.$newColorField
        .off('keyup.enableLabelCreateButton change.enableLabelCreateButton')
        .on('keyup.enableLabelCreateButton change.enableLabelCreateButton', this.enableLabelCreateButton.bind(this));

      this.$dropdownBack.off('click.resetForm').on('click.resetForm', this.resetForm.bind(this));

      this.$cancelButton.off('click.cancelForm').on('click.cancelForm', function(e) {
        e.preventDefault();
        e.stopPropagation();

        self.resetForm();
        self.$dropdownBack.trigger('click');
      });

      this.$newLabelCreateButton.off('click.saveLabel').on('click.saveLabel', this.saveLabel.bind(this));
    }

    addColorValue (e, $this) {
      e.preventDefault();
      e.stopPropagation();

      this.$newColorField.val($this.data('color')).trigger('change');
      this.$colorPreview
        .css('background-color', $this.data('color'))
        .parent()
        .addClass('is-active');
    }

    enableLabelCreateButton () {
      if (this.$newLabelField.val() !== '' && this.$newColorField.val() !== '') {
        this.$newLabelError.hide();
        this.$newLabelCreateButton.enable();
      } else {
        this.$newLabelCreateButton.disable();
      }
    }

    resetForm () {
      this.$newLabelField
        .val('')
        .trigger('change');

      this.$newColorField
        .val('')
        .trigger('change');

      this.$colorPreview
        .css('background-color', '')
        .parent()
        .removeClass('is-active');
    }

    saveLabel (e) {
      e.preventDefault();
      e.stopPropagation();

      Api.newLabel(this.namespacePath, this.projectPath, {
        title: this.$newLabelField.val(),
        color: this.$newColorField.val()
      }, (label) => {
        this.$newLabelCreateButton.enable();

        if (label.message) {
          let errors;

          if (typeof label.message === 'string') {
            errors = label.message;
          } else {
            errors = label.message.map(function (value, key) {
              return key + " " + value[0];
            }).join("<br/>");
          }

          this.$newLabelError
            .html(errors)
            .show();
        } else {
          this.$dropdownBack.trigger('click');

          $(document).trigger('created.label', label);
        }
      });
    }
  }

  if (!w.gl) {
    w.gl = {};
  }

  gl.CreateLabelDropdown = CreateLabelDropdown;
})(window);
