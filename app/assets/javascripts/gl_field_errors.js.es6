((global) => {
  /*
   * This class overrides the browser's validation error bubbles, displaying custom
   * error messages for invalid fields instead. To begin validating any form, add the
   * class `show-gl-field-errors` to the form element, and ensure error messages are
   * declared in each inputs' title attribute.
   *
   * Example:
   *
   * <form class='show-gl-field-errors'>
   *  <input type='text' name='username' title='Username is required.'/>
   *</form>
   *
    * */

  const errorMessageClass = 'gl-field-error';
  const inputErrorClass = 'gl-field-error-outline';

  class GlFieldError {
    constructor({ input, formErrors }) {
      this.inputElement = $(input);
      this.inputDomElement = this.inputElement.get(0);
      this.form = formErrors;
      this.errorMessage = this.inputElement.attr('title') || 'This field is required.';
      this.fieldErrorElement = $(`<p class='${errorMessageClass} hide'>${ this.errorMessage }</p>`);

      this.state = {
        valid: false,
        empty: true
      };

      this.initFieldValidation();
    }

    initFieldValidation() {
      // hidden when injected into DOM
      this.inputElement.after(this.fieldErrorElement);
      this.inputElement.off('invalid').on('invalid', this.handleInvalidInput.bind(this));
      this.scopedSiblings = this.safelySelectSiblings();
    }

    safelySelectSiblings() {
      // Apply `ignoreSelector` in markup to siblings whose visibility should not be toggled with input validity
      const ignoreSelector = '.validation-ignore';
      const unignoredSiblings = this.inputElement.siblings(`p:not(${ignoreSelector})`);
      const parentContainer = this.inputElement.parent('.form-group');

      // Only select siblings when they're scoped within a form-group with one input
      const safelyScoped = parentContainer.length && parentContainer.find('input').length === 1;

      return safelyScoped ? unignoredSiblings : this.fieldErrorElement;
    }

    renderValidity() {
      this.setClearState();

      if (this.state.valid) {
        return this.setValidState();
      }

      if (this.state.empty) {
        return this.setEmptyState();
      }

      if (!this.state.valid) {
        return this.setInvalidState();
      }

    }

    accessCurrentVal(newVal) {
      return newVal ? this.inputElement.val(newVal) : this.inputElement.val();
    }

    handleInvalidInput(event) {
      event.preventDefault();
      const currentValue = this.accessCurrentVal();
      this.state.valid = false;
      this.state.empty = currentValue === '';

      this.renderValidity();
      this.form.focusOnFirstInvalid.apply(this.form);
      // For UX, wait til after first invalid submission to check each keyup
      this.inputElement.off('keyup.field_validator')
        .on('keyup.field_validator', this.updateValidityState.bind(this));

    }

    getInputValidity() {
      return this.inputDomElement.validity.valid;
    }

    updateValidityState() {
      const inputVal = this.accessCurrentVal();
      this.state.empty = !inputVal.length;
      this.state.valid = this.getInputValidity();
      this.renderValidity();
    }

    setValidState() {
      return this.setClearState();
    }

    setEmptyState() {
      return this.setInvalidState();
    }

    setInvalidState() {
      this.inputElement.addClass(inputErrorClass);
      this.scopedSiblings.hide();
      return this.fieldErrorElement.show();
    }

    setClearState() {
      const inputVal = this.accessCurrentVal();
      if (!inputVal.split(' ').length) {
        const trimmedInput = inputVal.trim();
        this.accessCurrentVal(trimmedInput);
      }
      this.inputElement.removeClass(inputErrorClass);
      this.scopedSiblings.hide();
      this.fieldErrorElement.hide();
    }
  }

  const customValidationFlag = 'no-gl-field-errors';

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
      // select all non-hidden inputs in form
      this.state.inputs = this.form.find(':input:not([type=hidden])').toArray()
        .filter((input) => !input.classList.contains(customValidationFlag))
        .map((input) => new GlFieldError({ input, formErrors: this }));

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

    focusOnFirstInvalid () {
      const firstInvalid = this.state.inputs.filter((input) => !input.inputDomElement.validity.valid)[0];
      firstInvalid.inputElement.focus();
    }
  }

  global.GlFieldErrors = GlFieldErrors;

})(window.gl || (window.gl = {}));
