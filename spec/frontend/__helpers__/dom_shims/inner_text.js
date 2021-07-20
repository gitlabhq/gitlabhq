// workaround for JSDOM not supporting innerText
// see https://github.com/jsdom/jsdom/issues/1245
Object.defineProperty(global.Element.prototype, 'innerText', {
  get() {
    return this.textContent;
  },
  set(value) {
    this.textContent = value;
  },
  configurable: true, // make it so that it doesn't blow chunks on re-running tests with things like --watch
});
