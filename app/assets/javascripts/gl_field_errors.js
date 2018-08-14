import $ from 'jquery';
import GlFieldError from './gl_field_error';

const customValidationFlag = 'gl-field-error-ignore';

export default class GlFieldErrors {
  constructor(form) {
    this.form = $(form);
    this.state = {
      inputs: [],
      valid: false,
    };
    this.initValidators();
  }

  initValidators() {
    // register selectors here as needed
    const validateSelectors = [':text', ':password', '[type=email]']
      .map(selector => `input${selector}`).join(',');

    this.state.inputs = this.form.find(validateSelectors).toArray()
      .filter(input => !input.classList.contains(customValidationFlag))
      .map(input => new GlFieldError({ input, formErrors: this }));

    this.form.on('submit', GlFieldErrors.catchInvalidFormSubmit);
  }

  /* Neccessary to prevent intercept and override invalid form submit
   * because Safari & iOS quietly allow form submission when form is invalid
   * and prevents disabling of invalid submit button by application.js */

  static catchInvalidFormSubmit(e) {
    const $form = $(e.currentTarget);

    if (!$form.attr('novalidate')) {
      if (!e.currentTarget.checkValidity()) {
        e.preventDefault();
        e.stopPropagation();
      }
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

  focusOnFirstInvalid() {
    const firstInvalid = this.state.inputs
      .filter(input => !input.inputDomElement.validity.valid)[0];
    firstInvalid.inputElement.focus();
  }
}
