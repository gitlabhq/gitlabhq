import _ from 'underscore';
import InputValidator from '~/validators/input_validator';

import fetchGroupPathAvailability from './fetch_group_path_availability';
import flash from '~/flash';
import { __ } from '~/locale';

const debounceTimeoutDuration = 1000;
const invalidInputClass = 'gl-field-error-outline';
const successInputClass = 'gl-field-success-outline';
const successMessageSelector = '.validation-success';
const pendingMessageSelector = '.validation-pending';
const unavailableMessageSelector = '.validation-error';
const suggestionsMessageSelector = '.gl-path-suggestions';

export default class GroupPathValidator extends InputValidator {
  constructor(opts = {}) {
    super();

    const container = opts.container || '';
    const validateElements = document.querySelectorAll(`${container} .js-validate-group-path`);

    this.debounceValidateInput = _.debounce(inputDomElement => {
      GroupPathValidator.validateGroupPathInput(inputDomElement);
    }, debounceTimeoutDuration);

    validateElements.forEach(element =>
      element.addEventListener('input', this.eventHandler.bind(this)),
    );
  }

  eventHandler(event) {
    const inputDomElement = event.target;

    GroupPathValidator.resetInputState(inputDomElement);
    this.debounceValidateInput(inputDomElement);
  }

  static validateGroupPathInput(inputDomElement) {
    const groupPath = inputDomElement.value;

    if (inputDomElement.checkValidity() && groupPath.length > 0) {
      GroupPathValidator.setMessageVisibility(inputDomElement, pendingMessageSelector);

      fetchGroupPathAvailability(groupPath)
        .then(({ data }) => data)
        .then(data => {
          GroupPathValidator.setInputState(inputDomElement, !data.exists);
          GroupPathValidator.setMessageVisibility(inputDomElement, pendingMessageSelector, false);
          GroupPathValidator.setMessageVisibility(
            inputDomElement,
            data.exists ? unavailableMessageSelector : successMessageSelector,
          );

          if (data.exists) {
            GroupPathValidator.showSuggestions(inputDomElement, data.suggests);
          }
        })
        .catch(() => flash(__('An error occurred while validating group path')));
    }
  }

  static showSuggestions(inputDomElement, suggestions) {
    const messageElement = inputDomElement.parentElement.parentElement.querySelector(
      suggestionsMessageSelector,
    );
    const textSuggestions = suggestions && suggestions.length > 0 ? suggestions.join(', ') : 'none';
    messageElement.textContent = textSuggestions;
  }

  static setMessageVisibility(inputDomElement, messageSelector, isVisible = true) {
    const messageElement = inputDomElement.parentElement.parentElement.querySelector(
      messageSelector,
    );
    messageElement.classList.toggle('hide', !isVisible);
  }

  static setInputState(inputDomElement, success = true) {
    inputDomElement.classList.toggle(successInputClass, success);
    inputDomElement.classList.toggle(invalidInputClass, !success);
  }

  static resetInputState(inputDomElement) {
    GroupPathValidator.setMessageVisibility(inputDomElement, successMessageSelector, false);
    GroupPathValidator.setMessageVisibility(inputDomElement, unavailableMessageSelector, false);

    if (inputDomElement.checkValidity()) {
      inputDomElement.classList.remove(successInputClass, invalidInputClass);
    }
  }
}
