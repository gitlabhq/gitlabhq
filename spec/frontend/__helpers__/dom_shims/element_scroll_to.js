// Stores individual mocks for each Element instance
const scrollToMocks = new WeakMap();

Object.defineProperty(Element.prototype, 'scrollTo', {
  get() {
    if (!scrollToMocks.has(this)) {
      scrollToMocks.set(this, jest.fn());
    }
    return scrollToMocks.get(this);
  },
  set(fn) {
    scrollToMocks.set(this, fn);
  },
  configurable: true,
});
