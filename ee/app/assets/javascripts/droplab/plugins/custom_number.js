const CustomNumber = {
  keydown(e) {
    if (this.destroyed) return;

    const { list } = e.detail.hook;
    const { value } = e.detail.hook.trigger;
    const parsedValue = Number(value);
    const config = e.detail.hook.config.CustomNumber;
    const { defaultOptions } = config;

    const isValidNumber = !Number.isNaN(parsedValue) && value !== '';
    const customOption = [{ id: parsedValue, title: parsedValue }];
    const defaultDropdownOptions = defaultOptions.map(o => ({ id: o, title: o }));

    list.setData(isValidNumber ? customOption : defaultDropdownOptions);
    list.currentIndex = 0;
  },

  debounceKeydown(e) {
    if (
      [
        13, // enter
        16, // shift
        17, // ctrl
        18, // alt
        20, // caps lock
        37, // left arrow
        38, // up arrow
        39, // right arrow
        40, // down arrow
        91, // left window
        92, // right window
        93, // select
      ].indexOf(e.detail.which || e.detail.keyCode) > -1
    )
      return;

    if (this.timeout) clearTimeout(this.timeout);
    this.timeout = setTimeout(this.keydown.bind(this, e), 200);
  },

  init(hook) {
    this.hook = hook;
    this.destroyed = false;

    this.eventWrapper = {};
    this.eventWrapper.debounceKeydown = this.debounceKeydown.bind(this);

    this.hook.trigger.addEventListener('keydown.dl', this.eventWrapper.debounceKeydown);
    this.hook.trigger.addEventListener('mousedown.dl', this.eventWrapper.debounceKeydown);
  },

  destroy() {
    if (this.timeout) clearTimeout(this.timeout);
    this.destroyed = true;

    this.hook.trigger.removeEventListener('keydown.dl', this.eventWrapper.debounceKeydown);
    this.hook.trigger.removeEventListener('mousedown.dl', this.eventWrapper.debounceKeydown);
  },
};

export default CustomNumber;
