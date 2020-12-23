export class GitLabDropdownInput {
  constructor(input, options) {
    this.input = input;
    this.options = options;
    this.fieldName = this.options.fieldName || 'field-name';
    const $inputContainer = this.input.parent();
    const $clearButton = $inputContainer.find('.js-dropdown-input-clear');
    $clearButton.on('click', (e) => {
      // Clear click
      e.preventDefault();
      e.stopPropagation();
      return this.input.val('').trigger('input').focus();
    });

    this.input
      .on('keydown', (e) => {
        const keyCode = e.which;
        if (keyCode === 13 && !options.elIsInput) {
          e.preventDefault();
        }
      })
      .on('input', (e) => {
        let val = e.currentTarget.value || this.options.inputFieldName;
        val = val
          .split(' ')
          .join('-') // replaces space with dash
          .replace(/[^a-zA-Z0-9 -]/g, '')
          .toLowerCase() // replace non alphanumeric
          .replace(/(-)\1+/g, '-'); // replace repeated dashes
        this.cb(this.options.fieldName, val, {}, true);
        this.input.closest('.dropdown').find('.dropdown-toggle-text').text(val);
      });
  }

  onInput(cb) {
    this.cb = cb;
  }
}
