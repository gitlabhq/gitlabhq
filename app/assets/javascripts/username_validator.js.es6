((global) => {
  const debounceTimeoutDuration = 1000;
  const inputErrorClass = 'gl-field-error-outline';
  const inputSuccessClass = 'gl-field-success-outline';
  const messageErrorSelector = '.username .validation-error';
  const messageSuccessSelector = '.username .validation-success';
  const messagePendingSelector = '.username .validation-pending';

  class UsernameValidator {
    constructor() {
      this.inputElement = $('#new_user_username');
      this.inputDomElement = this.inputElement.get(0);

      this.available = false;
      this.valid = false;
      this.pending = false;
      this.fresh = true;
      this.empty = true;

      const debounceTimeout = _.debounce((username) => {
        this.validateUsername(username);
      }, debounceTimeoutDuration);

      this.inputElement.on('keyup.username_check', () => {
        const username = this.inputElement.val();

        this.valid = this.inputDomElement.validity.valid;
        this.fresh = false;
        this.empty = !username.length;

        if (this.valid) {
          return debounceTimeout(username);
        }

        this.renderState();
      });

      // Override generic field validation
      this.inputElement.on('invalid', this.handleInvalidInput.bind(this));
    }

    renderState() {
      // Clear all state
      this.clearFieldValidationState();

      if (this.valid && this.available) {
        return this.setSuccessState();
      }

      if (this.empty) {
        return this.clearFieldValidationState();
      }

      if (this.pending) {
        return this.setPendingState();
      }

      if (!this.available) {
        return this.setUnavailableState();
      }

      if (!this.valid) {
        return this.setInvalidState();
      }
    }

    handleInvalidInput(event) {
      event.preventDefault();
      event.stopPropagation();
    }

    validateUsername(username) {
      if (this.valid) {
        this.pending = true;
        this.available = false;
        this.renderState();
        return $.ajax({
          type: 'GET',
          url: `/u/${username}/exists`,
          dataType: 'json',
          success: (res) => this.updateValidationState(res.exists)
        });
      }
    }

    updateValidationState(usernameTaken) {
      if (usernameTaken) {
        this.valid = false;
        this.available = false;
      } else {
        this.available = true;
      }
      this.pending = false;
      this.renderState();
    }

    clearFieldValidationState() {
      this.inputElement.siblings('p').hide();
      this.inputElement.removeClass(inputErrorClass);
      this.inputElement.removeClass(inputSuccessClass);
    }

    setUnavailableState() {
      const $usernameErrorMessage = this.inputElement.siblings(messageErrorSelector);
      this.inputElement.addClass(inputErrorClass).removeClass(inputSuccessClass);
      $usernameErrorMessage.show();
    }

    setSuccessState() {
      const $usernameSuccessMessage = this.inputElement.siblings(messageSuccessSelector);
      this.inputElement.addClass(inputSuccessClass).removeClass(inputErrorClass);
      $usernameSuccessMessage.show();
    }

    setPendingState(show) {
      const $usernamePendingMessage = $(messagePendingSelector);
      if (this.pending) {
        $usernamePendingMessage.show();
      } else {
        $usernamePendingMessage.hide();
      }
    }

    setInvalidState() {
      this.inputElement.addClass(inputErrorClass).removeClass(inputSuccessClass);
      $(`.gl-field-error`).show();
    }
  }

  global.UsernameValidator = UsernameValidator;
})(window);
