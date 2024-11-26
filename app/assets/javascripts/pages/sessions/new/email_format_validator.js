import InputValidator from '~/validators/input_validator';

// The format of the email is validated by the default `type="email"` input field.
// In addition, the email should contain a top-level domain of at least two alphabetical characters.
const emailRegexPattern = /.+\.[a-zA-Z]{2,}/;
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
