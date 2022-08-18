import InputValidator from '~/validators/input_validator';

// It checks if email contains at least one character, number or whatever except
// another "@" or whitespace before "@", at least two characters except
// another "@" or whitespace after "@" and one dot in between
const emailRegexPattern = /[^@\s]+@[^@\s]+\.[^@\s]+/;
const hintMessageSelector = '.validation-hint';
const warningMessageSelector = '.validation-warning';

export default class EmailFormatValidator extends InputValidator {
  constructor(opts = {}) {
    super();

    const container = opts.container || '';

    document
      .querySelectorAll(`${container} .js-validate-email`)
      .forEach((element) =>
        element.addEventListener('keyup', EmailFormatValidator.eventHandler.bind(this)),
      );
  }

  static eventHandler(event) {
    const inputDomElement = event.target;

    EmailFormatValidator.setMessageVisibility(inputDomElement, hintMessageSelector);
    EmailFormatValidator.setMessageVisibility(inputDomElement, warningMessageSelector);
    EmailFormatValidator.validateEmailInput(inputDomElement);
  }

  static validateEmailInput(inputDomElement) {
    const validEmail = inputDomElement.checkValidity();
    const validPattern = inputDomElement.value.match(emailRegexPattern);

    EmailFormatValidator.setMessageVisibility(
      inputDomElement,
      warningMessageSelector,
      validEmail && !validPattern,
    );
  }

  static setMessageVisibility(inputDomElement, messageSelector, isVisible = false) {
    const messageElement = inputDomElement.parentElement.querySelector(messageSelector);
    messageElement.classList.toggle('hide', !isVisible);
  }
}
