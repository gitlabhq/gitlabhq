import $ from 'jquery';
import Api from '~/api';
import { humanize } from '~/lib/utils/text_utility';

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
    this.$addList = $('.js-add-list', this.$el);
    this.$newLabelError = $('.js-label-error', this.$el);
    this.$newLabelErrorContent = $('.gl-alert-content', this.$newLabelError);
    this.$newLabelCreateButton = $('.js-new-label-btn', this.$el);
    this.$colorSuggestions = $('.suggest-colors-dropdown a', this.$el);

    this.$newLabelError.hide();
    this.$newLabelCreateButton.disable();

    this.addListDefault = this.$addList.is(':checked');

    this.cleanBinding();
    this.addBinding();
  }

  cleanBinding() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$colorSuggestions.off('click');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$newLabelField.off('keyup change');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$newColorField.off('keyup change');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$colorPreview.off('keyup change');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$dropdownBack.off('click');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$cancelButton.off('click');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$newLabelCreateButton.off('click');
  }

  addBinding() {
    const self = this;

    // eslint-disable-next-line func-names
    this.$colorSuggestions.on('click', function (e) {
      const $this = $(this);
      self.addColorValue(e, $this);
    });

    this.$newLabelField.on('keyup change', this.enableLabelCreateButton.bind(this));
    this.$newColorField.on('keyup change', this.enableLabelCreateButton.bind(this));
    this.$colorPreview.on('keyup change', this.enableLabelCreateButton.bind(this));

    this.$newColorField.on('input', this.updateColorPreview.bind(this));
    this.$colorPreview.on('input', this.updateColorPickerPreview.bind(this));

    this.$dropdownBack.on('click', this.resetForm.bind(this));

    this.$cancelButton.on('click', (e) => {
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
    this.$colorPreview.val($this.data('color')).trigger('change');
  }

  updateColorPreview() {
    const previewColor = this.$newColorField.val();
    return this.$colorPreview.val(previewColor);
    // Updates the preview color with the hex-color input
  }

  updateColorPickerPreview() {
    const previewColor = this.$colorPreview.val();
    return this.$newColorField.val(previewColor);
    // Updates the input color with the hex-color from the picker
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
    this.$newLabelField.val('').trigger('change');

    this.$newColorField.val('').trigger('change');

    this.$addList.prop('checked', this.addListDefault);

    this.$colorPreview.val('');
  }

  saveLabel(e) {
    e.preventDefault();
    e.stopPropagation();

    Api.newLabel(
      this.namespacePath,
      this.projectPath,
      {
        title: this.$newLabelField.val(),
        color: this.$newColorField.val(),
      },
      (label) => {
        this.$newLabelCreateButton.enable();

        if (label.message) {
          let errors;

          if (typeof label.message === 'string') {
            errors = label.message;
          } else {
            errors = Object.keys(label.message)
              .map((key) => `${humanize(key)} ${label.message[key].join(', ')}`)
              .join('<br/>');
          }

          this.$newLabelErrorContent.html(errors);
          this.$newLabelError.show();
        } else {
          const addNewList = this.$addList.is(':checked');
          this.$dropdownBack.trigger('click');
          $(document).trigger('created.label', [label, addNewList]);
        }
      },
    );
  }
}
