/* eslint-disable */

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
    const inputAttribute = config.inputAttribute;

    if (input.hasAttribute(inputAttribute)) return input.setAttribute(inputAttribute, newValue);
    if (input.tagName === 'INPUT') return (input.value = newValue);
    return (input.textContent = newValue);
  },

  destroy() {
    this.destroyed = true;

    this.removeEvents();
  },
};

export default InputSetter;
