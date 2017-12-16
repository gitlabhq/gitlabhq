import { n__ } from '../locale';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';

export default class SecretValues {
  constructor(container) {
    this.container = container;
  }

  init() {
    this.values = this.container.querySelectorAll('.js-secret-value');
    this.placeholders = this.container.querySelectorAll('.js-secret-value-placeholder');
    this.revealButton = this.container.querySelector('.js-secret-value-reveal-button');

    this.revealText = n__('Reveal value', 'Reveal values', this.values.length);
    this.hideText = n__('Hide value', 'Hide values', this.values.length);

    const isRevealed = convertPermissionToBoolean(this.revealButton.dataset.secretRevealStatus);
    this.updateDom(isRevealed);

    this.revealButton.addEventListener('click', this.onRevealButtonClicked.bind(this));
  }

  onRevealButtonClicked() {
    const previousIsRevealed = convertPermissionToBoolean(
      this.revealButton.dataset.secretRevealStatus,
    );
    this.updateDom(!previousIsRevealed);
  }

  updateDom(isRevealed) {
    this.values.forEach((value) => {
      value.classList.toggle('hide', !isRevealed);
    });

    this.placeholders.forEach((placeholder) => {
      placeholder.classList.toggle('hide', isRevealed);
    });

    this.revealButton.textContent = isRevealed ? this.hideText : this.revealText;
    this.revealButton.dataset.secretRevealStatus = isRevealed;
  }
}
