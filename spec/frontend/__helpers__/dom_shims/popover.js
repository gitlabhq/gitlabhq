// jsdom doesn't implement the Popover API (https://github.com/jsdom/jsdom/issues/3721), which
// GlTooltip from @gitlab/ui is built on. Same behavior as the shim in @gitlab/ui's own specs.
const OPEN_ATTRIBUTE = 'data-popover-open';

const assertPopover = (el) => {
  if (!el.hasAttribute('popover')) {
    throw new DOMException('Not a popover element', 'NotSupportedError');
  }
};

const dispatchToggle = (el, oldState, newState) => {
  const event = new Event('toggle');
  Object.assign(event, { oldState, newState });
  el.dispatchEvent(event);
};

if (!HTMLElement.prototype.showPopover) {
  Object.defineProperties(HTMLElement.prototype, {
    showPopover: {
      configurable: true,
      writable: true,
      value() {
        assertPopover(this);
        if (this.hasAttribute(OPEN_ATTRIBUTE)) return;
        this.setAttribute(OPEN_ATTRIBUTE, '');
        dispatchToggle(this, 'closed', 'open');
      },
    },
    hidePopover: {
      configurable: true,
      writable: true,
      value() {
        assertPopover(this);
        if (!this.hasAttribute(OPEN_ATTRIBUTE)) return;
        this.removeAttribute(OPEN_ATTRIBUTE);
        dispatchToggle(this, 'open', 'closed');
      },
    },
    togglePopover: {
      configurable: true,
      writable: true,
      value(force) {
        const isOpen = this.hasAttribute(OPEN_ATTRIBUTE);
        const shouldOpen = force === undefined ? !isOpen : Boolean(force);
        if (shouldOpen && !isOpen) this.showPopover();
        if (!shouldOpen && isOpen) this.hidePopover();
        return shouldOpen;
      },
    },
  });

  // jsdom 20 doesn't throw on `:popover-open`, it always returns false. Report the shim's state.
  const { matches } = Element.prototype;
  Element.prototype.matches = function matchesWithPopoverOpen(selector) {
    if (selector === ':popover-open') return this.hasAttribute(OPEN_ATTRIBUTE);
    return matches.call(this, selector);
  };
}
