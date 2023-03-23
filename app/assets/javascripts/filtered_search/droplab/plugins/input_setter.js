const InputSetter = {
  init(hook) {
    this.hook = hook;
    this.destroyed = false;
    this.config = hook.config.InputSetter || (this.hook.config.InputSetter = {});

    this.eventWrapper = {};

    this.addEvents();
  },

  addEvents() {
    this.eventWrapper.setInputs = this.setInputs.bind(this);
    this.hook.list.list.addEventListener('click.dl', this.eventWrapper.setInputs);
  },

  removeEvents() {
    this.hook.list.list.removeEventListener('click.dl', this.eventWrapper.setInputs);
  },

  setInputs(e) {
    if (this.destroyed) return;

    const selectedItem = e.detail.selected;

    if (!Array.isArray(this.config)) this.config = [this.config];

    this.config.forEach((config) => this.setInput(config, selectedItem));
  },

  setInput(config, selectedItem) {
    const input = config.input || this.hook.trigger;
    const newValue = selectedItem.getAttribute(config.valueAttribute);
    const { inputAttribute } = config;

    if (input.hasAttribute(inputAttribute)) {
      input.setAttribute(inputAttribute, newValue);
    } else if (input.tagName === 'INPUT') {
      input.value = newValue;
    } else {
      input.textContent = newValue;
    }
  },

  destroy() {
    this.destroyed = true;

    this.removeEvents();
  },
};

export default InputSetter;
