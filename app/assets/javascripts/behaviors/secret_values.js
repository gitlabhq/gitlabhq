import { n__ } from '../locale';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';

export default class SecretValues {
  constructor({
    container,
    valueSelector = '.js-secret-value',
    placeholderSelector = '.js-secret-value-placeholder',
  }) {
    this.container = container;
    this.valueSelector = valueSelector;
    this.placeholderSelector = placeholderSelector;
  }

  init() {
    this.revealButton = this.container.querySelector('.js-secret-value-reveal-button');

    if (this.revealButton) {
      const isRevealed = convertPermissionToBoolean(this.revealButton.dataset.secretRevealStatus);
      this.updateDom(isRevealed);

      this.revealButton.addEventListener('click', this.onRevealButtonClicked.bind(this));
    }
  }

  onRevealButtonClicked() {
    const previousIsRevealed = convertPermissionToBoolean(
      this.revealButton.dataset.secretRevealStatus,
    );
    this.updateDom(!previousIsRevealed);
  }

  updateDom(isRevealed) {
    const values = this.container.querySelectorAll(this.valueSelector);
    values.forEach((value) => {
      value.classList.toggle('hidden', !isRevealed);
    });

    const placeholders = this.container.querySelectorAll(this.placeholderSelector);
    placeholders.forEach((placeholder) => {
      placeholder.classList.toggle('hidden', isRevealed);
    });

    this.revealButton.textContent = isRevealed ? n__('Hide value', 'Hide values', values.length) : n__('Reveal value', 'Reveal values', values.length);
    this.revealButton.dataset.secretRevealStatus = isRevealed;
  }
}
