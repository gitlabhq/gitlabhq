/* eslint-disable comma-dangle, class-methods-use-this, max-len, space-before-function-paren, arrow-parens, no-param-reassign */

require('./gl_field_error');

const customValidationFlag = 'gl-field-error-ignore';

class GlFieldErrors {
  constructor(form) {
    this.form = $(form);
    this.state = {
      inputs: [],
      valid: false
    };
    this.initValidators();
  }

  initValidators () {
    // register selectors here as needed
    const validateSelectors = [':text', ':password', '[type=email]']
      .map((selector) => `input${selector}`).join(',');

    this.state.inputs = this.form.find(validateSelectors).toArray()
      .filter((input) => !input.classList.contains(customValidationFlag))
      .map((input) => new window.gl.GlFieldError({ input, formErrors: this }));

    this.form.on('submit', this.catchInvalidFormSubmit);
  }

  /* Neccessary to prevent intercept and override invalid form submit
   * because Safari & iOS quietly allow form submission when form is invalid
   * and prevents disabling of invalid submit button by application.js */

  catchInvalidFormSubmit (event) {
    if (!event.currentTarget.checkValidity()) {
      event.preventDefault();
      event.stopPropagation();
    }
  }

  /* Public method for triggering validity updates manually  */
  updateFormValidityState() {
    this.state.inputs.forEach((field) => {
      if (field.state.submitted) {
        field.updateValidity();
      }
    });
  }

  focusOnFirstInvalid () {
    const firstInvalid = this.state.inputs.filter((input) => !input.inputDomElement.validity.valid)[0];
    firstInvalid.inputElement.focus();
  }
}

window.gl = window.gl || {};
window.gl.GlFieldErrors = GlFieldErrors;
