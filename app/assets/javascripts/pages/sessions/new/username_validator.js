/* eslint-disable comma-dangle, consistent-return, class-methods-use-this, arrow-parens, no-param-reassign, max-len */

import $ from 'jquery';
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';

const debounceTimeoutDuration = 1000;
const invalidInputClass = 'gl-field-error-outline';
const successInputClass = 'gl-field-success-outline';
const unavailableMessageSelector = '.username .validation-error';
const successMessageSelector = '.username .validation-success';
const pendingMessageSelector = '.username .validation-pending';
const invalidMessageSelector = '.username .gl-field-error';

export default class UsernameValidator {
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
      this.validateUsername(username);
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
      axios.get(`${gon.relative_url_root}/users/${username}/exists`)
        .then(({ data }) => this.setAvailabilityState(data.exists))
        .catch(() => flash(__('An error occurred while validating username')));
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
    this.inputElement.siblings('p').hide();

    this.inputElement.removeClass(invalidInputClass)
      .removeClass(successInputClass);
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
