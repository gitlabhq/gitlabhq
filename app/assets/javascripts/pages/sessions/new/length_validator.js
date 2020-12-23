import InputValidator from '../../../validators/input_validator';

const errorMessageClass = 'gl-field-error';

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
    const {
      minLength,
      minLengthMessage,
      maxLengthMessage,
      maxLength,
    } = this.inputDomElement.dataset;

    this.invalidInput = false;

    if (value.length > parseInt(maxLength, 10)) {
      this.invalidInput = true;
      this.errorMessage = maxLengthMessage;
    }

    if (value.length < parseInt(minLength, 10)) {
      this.invalidInput = true;
      this.errorMessage = minLengthMessage;
    }

    this.setValidationStateAndMessage();
  }
}
