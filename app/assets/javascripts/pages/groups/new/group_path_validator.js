import { debounce } from 'lodash';

import createFlash from '~/flash';
import { __ } from '~/locale';
import InputValidator from '~/validators/input_validator';
import fetchGroupPathAvailability from './fetch_group_path_availability';

const debounceTimeoutDuration = 1000;
const invalidInputClass = 'gl-field-error-outline';
const successInputClass = 'gl-field-success-outline';
const parentIdSelector = 'group_parent_id';
const successMessageSelector = '.validation-success';
const pendingMessageSelector = '.validation-pending';
const unavailableMessageSelector = '.validation-error';
const inputGroupSelector = '.input-group';

export default class GroupPathValidator extends InputValidator {
  constructor(opts = {}) {
    super();

    const container = opts.container || '';
    const validateElements = document.querySelectorAll(`${container} .js-validate-group-path`);
    const parentIdElement = document.getElementById(parentIdSelector);

    this.debounceValidateInput = debounce((inputDomElement) => {
      GroupPathValidator.validateGroupPathInput(inputDomElement, parentIdElement);
    }, debounceTimeoutDuration);

    validateElements.forEach((element) =>
      element.addEventListener('input', this.eventHandler.bind(this)),
    );
  }

  eventHandler(event) {
    const inputDomElement = event.target;

    GroupPathValidator.resetInputState(inputDomElement);
    this.debounceValidateInput(inputDomElement);
  }

  static validateGroupPathInput(inputDomElement, parentIdElement) {
    const groupPath = inputDomElement.value;
    const parentId = parentIdElement.value;

    if (inputDomElement.checkValidity() && groupPath.length > 1) {
      GroupPathValidator.setMessageVisibility(inputDomElement, pendingMessageSelector);

      fetchGroupPathAvailability(groupPath, parentId)
        .then(({ data }) => data)
        .then((data) => {
          GroupPathValidator.setInputState(inputDomElement, !data.exists);
          GroupPathValidator.setMessageVisibility(inputDomElement, pendingMessageSelector, false);
          GroupPathValidator.setMessageVisibility(
            inputDomElement,
            data.exists ? unavailableMessageSelector : successMessageSelector,
          );

          if (data.exists) {
            const [suggestedSlug] = data.suggests;
            const targetDomElement = document.querySelector('.js-autofill-group-path');
            targetDomElement.value = suggestedSlug;
          }
        })
        .catch(() =>
          createFlash({
            message: __('An error occurred while validating group path'),
          }),
        );
    }
  }

  static setMessageVisibility(inputDomElement, messageSelector, isVisible = true) {
    const messageElement = inputDomElement
      .closest(inputGroupSelector)
      .parentElement.querySelector(messageSelector);

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
