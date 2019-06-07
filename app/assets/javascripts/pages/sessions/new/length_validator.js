import InputValidator from '../../../validators/input_validator';

const errorMessageClass = 'gl-field-error';

export default class LengthValidator extends InputValidator {
  constructor(opts = {}) {
    super();

    const container = opts.container || '';
    const validateLengthElements = document.querySelectorAll(`${container} .js-validate-length`);

    validateLengthElements.forEach(element =>
      element.addEventListener('input', this.eventHandler.bind(this)),
    );
  }

  eventHandler(event) {
    this.inputDomElement = event.target;
    this.inputErrorMessage = this.inputDomElement.parentElement.querySelector(
      `.${errorMessageClass}`,
    );

    const { value } = this.inputDomElement;
    const { maxLengthMessage, maxLength } = this.inputDomElement.dataset;

    this.errorMessage = maxLengthMessage;

    this.invalidInput = value.length > parseInt(maxLength, 10);

    this.setValidationStateAndMessage();
  }
}
