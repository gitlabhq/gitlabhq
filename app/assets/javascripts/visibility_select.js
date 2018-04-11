export default class VisibilitySelect {
  constructor(container) {
    if (!container) throw new Error('VisibilitySelect requires a container element as argument 1');
    this.container = container;
    this.helpBlock = this.container.querySelector('.form-text.text-muted');
    this.select = this.container.querySelector('select');
  }

  init() {
    if (this.select) {
      this.updateHelpText();
      this.select.addEventListener('change', this.updateHelpText.bind(this));
    } else {
      this.helpBlock.textContent = this.container.querySelector('.js-locked').dataset.helpBlock;
    }
  }

  updateHelpText() {
    this.helpBlock.textContent = this.select.querySelector('option:checked').dataset.description;
  }
}
