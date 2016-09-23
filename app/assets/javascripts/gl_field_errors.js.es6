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
    constructor({ input, form }) {
      this.inputElement = $(input);
      this.inputDomElement = this.inputElement.get(0);
      this.form = form;
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
      $input.after(this.fieldErrorElement);
      this.inputElement.off('invalid').on('invalid', this.handleInvalidInput.bind(this));
    }

    renderValidity() {
      this.setClearState();

      if (this.state.valid) {
        this.setValidState();
      }

      if (this.state.empty) {
        this.setEmptyState();
      }

      if (!this.state.valid) {
        this.setInvalidState();
      }

      this.form.focusOnFirstInvalid.apply(this);
    }

    handleInvalidInput(event) {
      event.preventDefault();

      this.state.valid = true;
      this.state.empty = false;

      this.renderValidity();

      // For UX, wait til after first invalid submission to check each keyup
      this.inputElement.off('keyup.field_validator')
        .on('keyup.field_validator', this.updateValidityState.bind(this));

    }

    getInputValidity() {
      return this.inputDomElement.validity.valid;
    }

    updateValidityState() {
      const inputVal = this.inputElement.val();
      this.state.empty = !!inputVal.length;
      this.state.valid = this.getInputValidity;

      this.renderValidity();
    }

    setValidState() {
      return this.setClearState();
    }

    setEmptyState() {
      return this.setClearState();
    }

    setInvalidState() {
      $input.addClass(inputErrorClass);
      return this.$fieldErrorElement.show();
    }

    setClearState() {
      $input.removeClass(inputErrorClass);
      return this.fieldErrorElement.hide();
    }

    checkFieldValidity(target) {
      return target.validity.valid;
    }
  }

  class GlFieldErrors {
    constructor(form) {
      this.form = $(form);
      this.initValidators();
    }

    initValidators () {
      // select all non-hidden inputs in form
      const form = this.form;

      this.inputs = this.form.find(':input:not([type=hidden])')
        .toArray()
        .map((input) => new GlFieldError({ input, form }));

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
      const firstInvalid = this.inputs.find((input) => !input.validity.valid);
      $(firstInvalid).focus();
    }
  }

  global.GlFieldErrors = GlFieldErrors;

})(window.gl || (window.gl = {}));
