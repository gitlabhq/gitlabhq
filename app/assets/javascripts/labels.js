import $ from 'jquery';

export default class Labels {
  constructor() {
    this.setSuggestedColor = this.setSuggestedColor.bind(this);
    this.updateColorPreview = this.updateColorPreview.bind(this);
    this.cleanBinding();
    this.addBinding();
    this.updateColorPreview();
  }

  addBinding() {
    $(document).on('click', '.suggest-colors a', this.setSuggestedColor);
    return $(document).on('input', 'input#label_color', this.updateColorPreview);
  }
  // eslint-disable-next-line class-methods-use-this
  cleanBinding() {
    $(document).off('click', '.suggest-colors a');
    return $(document).off('input', 'input#label_color');
  }
  // eslint-disable-next-line class-methods-use-this
  updateColorPreview() {
    const previewColor = $('input#label_color').val();
    return $('div.label-color-preview').css('background-color', previewColor);
  // Updates the the preview color with the hex-color input
  }

  // Updates the preview color with a click on a suggested color
  setSuggestedColor(e) {
    const color = $(e.currentTarget).data('color');
    $('input#label_color').val(color);
    this.updateColorPreview();
    // Notify the form, that color has changed
    $('.label-form').trigger('keyup');
    return e.preventDefault();
  }
}
