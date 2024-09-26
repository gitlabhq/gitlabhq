import Tracking from '~/tracking';
import { convertToSnakeCase } from '~/lib/utils/text_utility';

export default class FormErrorTracker {
  constructor() {
    this.elements = document.querySelectorAll('.js-track-error');
    this.trackErrorOnChange = FormErrorTracker.trackErrorOnChange.bind(this);
    this.trackErrorOnEmptyField = FormErrorTracker.trackErrorOnEmptyField.bind(this);

    this.elements.forEach((element) => {
      // https://gitlab.com/gitlab-org/gitlab/-/issues/494329 to revert this condition when
      // blocker is implemented
      const actionItem = element.hasChildNodes() ? element.firstElementChild : element;

      if (actionItem) {
        // on item change
        actionItem.addEventListener('input', this.trackErrorOnChange);

        // on invalid item - adding separately to track submit click without
        // changing any field
        actionItem.addEventListener('invalid', this.trackErrorOnEmptyField);
      }
    });
  }

  destroy() {
    this.elements.forEach((element) => {
      const actionItem = element.hasChildNodes() ? element.firstElementChild : element;

      if (actionItem) {
        actionItem.removeEventListener('input', this.trackErrorOnChange);
        actionItem.removeEventListener('invalid', this.trackErrorOnEmptyField);
      }
    });
  }

  static trackErrorOnChange(event) {
    const inputDomElement = event.target;

    if (inputDomElement.value && !inputDomElement.checkValidity()) {
      const message = FormErrorTracker.errorMessage(inputDomElement);

      Tracking.event(undefined, FormErrorTracker.action(inputDomElement), {
        label: FormErrorTracker.label(inputDomElement, message),
      });
    }
  }

  static trackErrorOnEmptyField(event) {
    const inputDomElement = event.target;

    if (inputDomElement.value === '' || !inputDomElement.checked) {
      const message = FormErrorTracker.inputErrorMessage(inputDomElement);

      Tracking.event(undefined, FormErrorTracker.action(inputDomElement), {
        label: FormErrorTracker.label(inputDomElement, message),
      });
    }
  }

  static errorMessage(element) {
    if (element.id.includes('email')) {
      return 'invalid_email_address';
    }

    if (element.id.includes('password')) {
      return 'password_is_too_short';
    }

    return FormErrorTracker.inputErrorMessage(element);
  }

  static inputErrorMessage(element) {
    return convertToSnakeCase(element.validationMessage);
  }

  static action(element) {
    return `track_${element.dataset.trackActionForErrors}_error`;
  }

  static label(element, message) {
    if (element.type === 'radio') {
      const labelText = element.closest('.form-group').querySelector('label').textContent;
      return `missing_${convertToSnakeCase(labelText)}`;
    }

    return `${element.id}_${message}`;
  }
}
