import InputValidator from '~/validators/input_validator';

const errorMessageClass = 'gl-field-error';

export const isAboveMaxLength = (str, maxLength) => {
  return str.length > parseInt(maxLength, 10);
};

export const isBelowMinLength = (value, minLength, allowEmpty) => {
  const isValueNotAllowedOrNotEmpty = allowEmpty !== 'true' || value.length !== 0;
  const isValueBelowMinLength = value.length < parseInt(minLength, 10);
  return isValueBelowMinLength && isValueNotAllowedOrNotEmpty;
};

export default class LengthValidator extends InputValidator {
  constructor(opts = {}) {
    super();

    const container = opts.container || '';
    const validateLengthElements = document.querySelectorAll(`${container} .js-validate-length`);

    validateLengthElements.forEach((element) =>
      element.addEventListener('input', this.eventHandler.bind(this)),
    );
  }

  eventHandler(event) {
    this.inputDomElement = event.target;
    this.inputErrorMessage = this.inputDomElement.parentElement.querySelector(
      `.${errorMessageClass}`,
    );

    const { value } = this.inputDomElement;
    const { minLength, minLengthMessage, maxLengthMessage, maxLength, allowEmpty } =
      this.inputDomElement.dataset;

    this.invalidInput = false;

    if (isAboveMaxLength(value, maxLength)) {
      this.invalidInput = true;
      this.errorMessage = maxLengthMessage;
    }

    if (isBelowMinLength(value, minLength, allowEmpty)) {
      this.invalidInput = true;
      this.errorMessage = minLengthMessage;
    }

    this.setValidationStateAndMessage();
  }
}
