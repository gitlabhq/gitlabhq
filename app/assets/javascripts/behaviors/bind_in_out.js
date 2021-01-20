class BindInOut {
  constructor(bindIn, bindOut) {
    this.in = bindIn;
    this.out = bindOut;

    this.eventWrapper = {};
    this.eventType = /(INPUT|TEXTAREA)/.test(bindIn.tagName) ? 'keyup' : 'change';
  }

  addEvents() {
    this.eventWrapper.updateOut = this.updateOut.bind(this);

    this.in.addEventListener(this.eventType, this.eventWrapper.updateOut);

    return this;
  }

  updateOut() {
    this.out.textContent = this.in.value;

    return this;
  }

  removeEvents() {
    this.in.removeEventListener(this.eventType, this.eventWrapper.updateOut);

    return this;
  }

  static initAll() {
    const ins = document.querySelectorAll('*[data-bind-in]');

    return [].map.call(ins, (anIn) => BindInOut.init(anIn));
  }

  static init(anIn, anOut) {
    const out = anOut || document.querySelector(`*[data-bind-out="${anIn.dataset.bindIn}"]`);

    if (!out) return null;

    const bindInOut = new BindInOut(anIn, out);

    return bindInOut.addEvents().updateOut();
  }
}

export default BindInOut;
