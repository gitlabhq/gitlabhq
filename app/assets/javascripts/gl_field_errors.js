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
    const validateSelectors = [
      'input:text',
      'input:password',
      'input[type=email]',
      'input[type=url]',
      'input[type=number]',
      'textarea',
      'select',
    ].join(',');

    this.state.inputs = this.form
      .find(validateSelectors)
      .toArray()
      .filter((input) => !input.classList.contains(customValidationFlag))
      .map((input) => new GlFieldError({ input, formErrors: this }));

    this.form.on('submit', GlFieldErrors.catchInvalidFormSubmit);
  }

  /* Necessary to prevent intercept and override invalid form submit
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

  get invalidInputs() {
    return this.state.inputs.filter(
      ({
        inputDomElement: {
          validity: { valid },
        },
      }) => !valid,
    );
  }

  get focusedInvalidInput() {
    return this.invalidInputs.find(({ inputElement }) => inputElement.is(':focus'));
  }

  focusInvalid() {
    if (this.focusedInvalidInput) return;

    this.invalidInputs[0].inputElement.focus();
  }
}
