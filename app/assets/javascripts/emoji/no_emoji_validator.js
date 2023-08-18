import emojiRegex from 'emoji-regex';
import { __ } from '~/locale';
import InputValidator from '../validators/input_validator';

export default class NoEmojiValidator extends InputValidator {
  constructor(opts = {}) {
    super();

    const container = opts.container || '';
    this.noEmojiEmelents = document.querySelectorAll(`${container} .js-block-emoji`);

    this.noEmojiEmelents.forEach((element) =>
      element.addEventListener('input', this.eventHandler.bind(this)),
    );
  }

  eventHandler(event) {
    this.inputDomElement = event.target;
    this.inputErrorMessage = this.inputDomElement.nextSibling;

    const { value } = this.inputDomElement;

    this.errorMessage = __('Invalid input, please avoid emoji');

    this.validatePattern(value);
    this.setValidationStateAndMessage();
  }

  validatePattern(value) {
    const pattern = emojiRegex();
    this.invalidInput = new RegExp(pattern).test(value);
  }
}
