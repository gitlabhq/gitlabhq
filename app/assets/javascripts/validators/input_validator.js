const invalidInputClass = 'gl-field-error-outline';

export default class InputValidator {
  constructor() {
    this.inputDomElement = {};
    this.inputErrorMessage = {};
    this.errorMessage = null;
    this.invalidInput = null;
  }

  setValidationStateAndMessage() {
    this.setValidationMessage();

    const isInvalidInput = !this.inputDomElement.checkValidity();
    this.inputDomElement.classList.toggle(invalidInputClass, isInvalidInput);
    this.inputErrorMessage.classList.toggle('hide', !isInvalidInput);
  }

  setValidationMessage() {
    if (this.invalidInput) {
      this.inputDomElement.setCustomValidity(this.errorMessage);
      // eslint-disable-next-line no-unsanitized/property
      this.inputErrorMessage.innerHTML = this.errorMessage;
    } else {
      this.resetValidationMessage();
    }
  }

  resetValidationMessage() {
    if (this.inputDomElement.validationMessage === this.errorMessage) {
      this.inputDomElement.setCustomValidity('');
      // eslint-disable-next-line no-unsanitized/property
      this.inputErrorMessage.innerHTML = this.inputDomElement.title;
    }
  }
}
