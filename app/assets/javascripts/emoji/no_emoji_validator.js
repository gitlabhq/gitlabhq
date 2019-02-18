import { __ } from '~/locale';
import emojiRegex from 'emoji-regex';

const invalidInputClass = 'gl-field-error-outline';

export default class NoEmojiValidator {
  constructor(opts = {}) {
    const container = opts.container || '';
    this.noEmojiEmelents = document.querySelectorAll(`${container} .js-block-emoji`);

    this.noEmojiEmelents.forEach(element =>
      element.addEventListener('input', this.eventHandler.bind(this)),
    );
  }

  eventHandler(event) {
    this.inputDomElement = event.target;
    this.inputErrorMessage = this.inputDomElement.nextSibling;

    const { value } = this.inputDomElement;

    this.validatePattern(value);
    this.setValidationStateAndMessage();
  }

  validatePattern(value) {
    const pattern = emojiRegex();
    this.hasEmojis = new RegExp(pattern).test(value);

    if (this.hasEmojis) {
      this.inputDomElement.setCustomValidity(__('Invalid input, please avoid emojis'));
    } else {
      this.inputDomElement.setCustomValidity('');
    }
  }

  setValidationStateAndMessage() {
    if (!this.inputDomElement.checkValidity()) {
      this.setInvalidState();
    } else {
      this.clearFieldValidationState();
    }
  }

  clearFieldValidationState() {
    this.inputDomElement.classList.remove(invalidInputClass);
    this.inputErrorMessage.classList.add('hide');
  }

  setInvalidState() {
    this.inputDomElement.classList.add(invalidInputClass);
    this.setErrorMessage();
  }

  setErrorMessage() {
    if (this.hasEmojis) {
      this.inputErrorMessage.innerHTML = this.inputDomElement.validationMessage;
    } else {
      this.inputErrorMessage.innerHTML = this.inputDomElement.title;
    }
    this.inputErrorMessage.classList.remove('hide');
  }
}
