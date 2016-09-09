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

  const fieldErrorClass = 'gl-field-error';
  const fieldErrorSelector = `.${fieldErrorClass}`;
  const inputErrorClass = 'gl-field-error-outline';

  class GlFieldErrors {
    constructor(form) {
      this.form = $(form);
      this.initValidators();
    }

    initValidators () {
      this.inputs = this.form.find(':input:not([type=hidden])').toArray();
      this.inputs.forEach((input) => {
        $(input).off('invalid').on('invalid', this.handleInvalidInput.bind(this));
      });
      this.form.on('submit', this.catchInvalidFormSubmit);
    }

    /* Neccessary because Safari & iOS quietly allow form submission when form is invalid */
    catchInvalidFormSubmit (event) {
      if (!event.currentTarget.checkValidity()) {
        event.preventDefault();
        // Prevents disabling of invalid submit button by application.js
        event.stopPropagation();
      }
    }

    handleInvalidInput (event) {
      event.preventDefault();
      this.updateFieldValidityState(event);

      const $input = $(event.currentTarget);

      // For UX, wait til after first invalid submission to check each keyup
      $input.off('keyup.field_validator')
        .on('keyup.field_validator', this.updateFieldValidityState.bind(this));

    }

    displayFieldValidity (target, isValid) {
      const $input = $(target).removeClass(inputErrorClass);
      const $existingError = $input.siblings(fieldErrorSelector);
      const alreadyInvalid = !!$existingError.length;
      const implicitErrorMessage = $input.attr('title');
      const $errorToDisplay = alreadyInvalid ? $existingError.detach() : $(`<p class="${fieldErrorClass}">${implicitErrorMessage}</p>`);

      if (!isValid) {
        $input.after($errorToDisplay);
        $input.addClass(inputErrorClass);
      }

      this.updateFieldSiblings($errorToDisplay, isValid);
    }

    updateFieldSiblings($target, isValid) {
      const siblings = $target.siblings(`p${fieldErrorSelector}`);
      return isValid ? siblings.show() : siblings.hide();
    }

    checkFieldValidity(target) {
      return target.validity.valid;
    }

    updateFieldValidityState(event) {
      const target = event.currentTarget;
      const isKeyup = event.type === 'keyup';
      const isValid = this.checkFieldValidity(target);

      this.displayFieldValidity(target, isValid);

      // prevent changing focus while user is typing.
      if (!isKeyup) {
        this.focusOnFirstInvalid.apply(this);
      }
    }

    focusOnFirstInvalid () {
      const firstInvalid = this.inputs.find((input) => !input.validity.valid);
      $(firstInvalid).focus();
    }
  }

  global.GlFieldErrors = GlFieldErrors;

})(window.gl || (window.gl = {}));
