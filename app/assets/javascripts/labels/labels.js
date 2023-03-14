import $ from 'jquery';

export default class Labels {
  constructor() {
    this.setSuggestedColor = this.setSuggestedColor.bind(this);
    this.updateColorPreview = this.updateColorPreview.bind(this);
    this.cleanBinding();
    this.addBinding();
    this.updateColorPreview();
    this.updateColorPickerPreview();
  }

  addBinding() {
    $(document).on('click', '.suggest-colors a', this.setSuggestedColor);
    $(document).on('input', '.label-color-preview', this.updateColorPickerPreview);
    return $(document).on('input', 'input#label_color', this.updateColorPreview);
  }
  // eslint-disable-next-line class-methods-use-this
  cleanBinding() {
    $(document).off('click', '.suggest-colors a');
    $(document).off('input', '.label-color-preview');
    return $(document).off('input', 'input#label_color');
  }
  // eslint-disable-next-line class-methods-use-this
  updateColorPreview() {
    const previewColor = $('input#label_color').val();
    return $('.label-color-preview').val(previewColor);
    // Updates the preview color with the hex-color input
  }
  // eslint-disable-next-line class-methods-use-this
  updateColorPickerPreview() {
    const previewColor = $('.label-color-preview').val();
    return $('input#label_color').val(previewColor);
    // Updates the input color with the hex-color from the picker
  }

  // Updates the preview color with a click on a suggested color
  setSuggestedColor(e) {
    const color = $(e.currentTarget).data('color');
    $('input#label_color').val(color);
    this.updateColorPreview();
    this.updateColorPickerPreview();
    // Notify the form, that color has changed
    $('.label-form').trigger('keyup');
    return e.preventDefault();
  }
}
