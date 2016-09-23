((global) => {
  const debounceTimeoutDuration = 1000;
  const invalidInputClass = 'gl-field-error-outline';
  const successInputClass = 'gl-field-success-outline';
  const unavailableMessageSelector = '.username .validation-error';
  const successMessageSelector = '.username .validation-success';
  const pendingMessageSelector = '.username .validation-pending';
  const invalidMessageSelector = '.username .gl-field-error';

  class UsernameValidator {
    constructor() {
      this.inputElement = $('#new_user_username');
      this.inputDomElement = this.inputElement.get(0);
      this.state = {
        available: false,
        valid: false,
        pending: false,
        empty: true
      };

      const debounceTimeout = _.debounce((username) => {
        this.state.validateUsername(username);
      }, debounceTimeoutDuration);

      this.inputElement.on('keyup.username_check', () => {
        const username = this.inputElement.val();

        this.state.valid = this.inputDomElement.validity.valid;
        this.state.empty = !username.length;

        if (this.state.valid) {
          return debounceTimeout(username);
        }

        this.renderState();
      });

      // Override generic field validation
      this.inputElement.on('invalid', this.interceptInvalid.bind(this));
    }

    renderState() {
      // Clear all state
      this.clearFieldValidationState();

      if (this.state.valid && this.state.available) {
        return this.setSuccessState();
      }

      if (this.state.empty) {
        return this.clearFieldValidationState();
      }

      if (this.state.pending) {
        return this.setPendingState();
      }

      if (!this.state.available) {
        return this.setUnavailableState();
      }

      if (!this.state.valid) {
        return this.setInvalidState();
      }
    }

    interceptInvalid(event) {
      event.preventDefault();
      event.stopPropagation();
    }

    validateUsername(username) {
      if (this.state.valid) {
        this.state.pending = true;
        this.state.available = false;
        this.renderState();
        return $.ajax({
          type: 'GET',
          url: `/u/${username}/exists`,
          dataType: 'json',
          success: (res) => this.updateValidationState(res.exists)
        });
      }
    }

    setAvailabilityState(usernameTaken) {
      if (usernameTaken) {
        this.state.valid = false;
        this.state.available = false;
      } else {
        this.state.available = true;
      }
      this.state.pending = false;
      this.renderState();
    }

    clearFieldValidationState() {
      // TODO: Double check if this is valid chaining
      const $input = this.inputElement
        .siblings('p').hide().end()
        .removeClass(invalidInputClass);
         removeClass(successInputClass);
    }

    setUnavailableState() {
      const $usernameUnavailableMessage = this.inputElement.siblings(unavailableMessageSelector);
      this.inputElement.addClass(invalidInputClass).removeClass(successInputClass);
      $usernameUnavailableMessage.show();
    }

    setSuccessState() {
      const $usernameSuccessMessage = this.inputElement.siblings(successMessageSelector);
      this.inputElement.addClass(successInputClass).removeClass(invalidInputClass);
      $usernameSuccessMessage.show();
    }

    setPendingState() {
      const $usernamePendingMessage = $(pendingMessageSelector);
      if (this.state.pending) {
        $usernamePendingMessage.show();
      } else {
        $usernamePendingMessage.hide();
      }
    }

    setInvalidState() {
      const $inputErrorMessage = $(invalidMessageSelector);
      this.inputElement.addClass(invalidInputClass).removeClass(successInputClass);
      $inputErrorMessage.show();
    }
  }

  global.UsernameValidator = UsernameValidator;
})(window);
