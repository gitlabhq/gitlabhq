/* eslint-disable func-names, prefer-arrow-callback */

import $ from 'jquery';
import Api from './api';
import { humanize } from './lib/utils/text_utility';

export default class CreateLabelDropdown {
  constructor($el, namespacePath, projectPath) {
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

  cleanBinding() {
    this.$colorSuggestions.off('click');
    this.$newLabelField.off('keyup change');
    this.$newColorField.off('keyup change');
    this.$dropdownBack.off('click');
    this.$cancelButton.off('click');
    this.$newLabelCreateButton.off('click');
  }

  addBinding() {
    const self = this;

    this.$colorSuggestions.on('click', function (e) {
      const $this = $(this);
      self.addColorValue(e, $this);
    });

    this.$newLabelField.on('keyup change', this.enableLabelCreateButton.bind(this));
    this.$newColorField.on('keyup change', this.enableLabelCreateButton.bind(this));

    this.$dropdownBack.on('click', this.resetForm.bind(this));

    this.$cancelButton.on('click', function (e) {
      e.preventDefault();
      e.stopPropagation();

      self.resetForm();
      self.$dropdownBack.trigger('click');
    });

    this.$newLabelCreateButton.on('click', this.saveLabel.bind(this));
  }

  addColorValue(e, $this) {
    e.preventDefault();
    e.stopPropagation();

    this.$newColorField.val($this.data('color')).trigger('change');
    this.$colorPreview
      .css('background-color', $this.data('color'))
      .parent()
      .addClass('is-active');
  }

  enableLabelCreateButton() {
    if (this.$newLabelField.val() !== '' && this.$newColorField.val() !== '') {
      this.$newLabelError.hide();
      this.$newLabelCreateButton.enable();
    } else {
      this.$newLabelCreateButton.disable();
    }
  }

  resetForm() {
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

  saveLabel(e) {
    e.preventDefault();
    e.stopPropagation();

    Api.newLabel(this.namespacePath, this.projectPath, {
      title: this.$newLabelField.val(),
      color: this.$newColorField.val(),
    }, (label) => {
      this.$newLabelCreateButton.enable();

      if (label.message) {
        let errors;

        if (typeof label.message === 'string') {
          errors = label.message;
        } else {
          errors = Object.keys(label.message).map(key =>
            `${humanize(key)} ${label.message[key].join(', ')}`,
          ).join('<br/>');
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
