(() => {
  const global = window.gl || (window.gl = {});

  const VISIBILITY_DESCRIPTIONS = {
    0: 'Project access must be granted explicitly to each user.',
    10: 'Project access must be granted explicitly to each user.',
    20: 'The project can be cloned without any authentication.',
  };

  class VisibilitySelect {
    constructor() {
      this.visibilitySelect = document.querySelector('.js-visibility-select');
      this.helpBlock = this.visibilitySelect.querySelector('.help-block');
      this.select = this.visibilitySelect.querySelector('select');
      if (this.select) {
        this.visibilityChanged();
        this.select.addEventListener('change', this.visibilityChanged.bind(this));
      } else {
        this.helpBlock.textContent = this.visibilitySelect.querySelector('.js-locked').dataset.helpBlock;
      }
    }

    visibilityChanged() {
      this.helpBlock.innerText = VISIBILITY_DESCRIPTIONS[this.select.value];
    }
  }

  global.VisibilitySelect = VisibilitySelect;
})();
