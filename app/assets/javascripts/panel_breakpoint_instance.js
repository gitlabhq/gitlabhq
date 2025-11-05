class PanelBreakpointManager {
  static MAIN_CONTAINER_SELECTOR =
    '.js-static-panel-inner #content-body, .js-container-queries-enabled > *';

  static BREAKPOINTS = new Map([
    ['xl', 1200],
    ['lg', 992],
    ['md', 768],
    ['sm', 576],
    ['xs', 0],
  ]);

  static getBreakpointIndex(breakpoint) {
    return Array.from(PanelBreakpointManager.BREAKPOINTS.keys()).indexOf(breakpoint);
  }

  #observer = null;
  #resizeHandlers = new Set();
  #breakpointSubscribers = new Set();
  #cachedWidth = 0;
  #currentBreakpoint = null;
  #mainContainer = null;

  constructor() {
    this.#updateCache();
    this.#currentBreakpoint = this.#calculateBreakpoint();
  }

  availableWidth() {
    return this.#cachedWidth;
  }

  addResizeListener(handler) {
    this.#resizeHandlers.add(handler);
    this.#initializeObserver();
  }

  addBreakpointListener(handler) {
    this.#breakpointSubscribers.add(handler);
    this.#initializeObserver();
  }

  removeResizeListener(handler) {
    this.#resizeHandlers.delete(handler);
  }

  removeBreakpointListener(handler) {
    this.#breakpointSubscribers.delete(handler);
  }

  getBreakpointSize() {
    return this.#currentBreakpoint;
  }

  isDesktop() {
    return ['xl', 'lg'].includes(this.#currentBreakpoint);
  }

  /**
   * Checks if current breakpoint is greater than or equal to the specified breakpoint
   * @param {string} breakpoint - Breakpoint to compare ('xl', 'lg', 'md', 'sm', 'xs')
   * @returns {boolean}
   * @example
   * // If current is 'lg':
   * isBreakpointUp('md') // true (lg >= md)
   * isBreakpointUp('xl') // false (lg < xl)
   */
  isBreakpointUp(breakpoint) {
    const currentIndex = PanelBreakpointManager.getBreakpointIndex(this.#currentBreakpoint);
    const targetIndex = PanelBreakpointManager.getBreakpointIndex(breakpoint);
    return currentIndex <= targetIndex;
  }

  /**
   * Checks if current breakpoint is less than or equal to the specified breakpoint
   * @param {string} breakpoint - Breakpoint to compare ('xl', 'lg', 'md', 'sm', 'xs')
   * @returns {boolean}
   * @example
   * // If current is 'md':
   * isBreakpointDown('lg') // true (md <= lg)
   * isBreakpointDown('sm') // false (md > sm)
   */
  isBreakpointDown(breakpoint) {
    const currentIndex = PanelBreakpointManager.getBreakpointIndex(this.#currentBreakpoint);
    const targetIndex = PanelBreakpointManager.getBreakpointIndex(breakpoint);
    return currentIndex >= targetIndex;
  }

  #getMainContainer() {
    if (!this.#mainContainer) {
      this.#mainContainer = document.querySelector(PanelBreakpointManager.MAIN_CONTAINER_SELECTOR);
    }
    return this.#mainContainer;
  }

  #updateCache() {
    const container = this.#getMainContainer();
    this.#cachedWidth = container ? container.clientWidth : window.innerWidth;
  }

  #calculateBreakpoint() {
    const { BREAKPOINTS } = PanelBreakpointManager;

    for (const [name, minWidth] of BREAKPOINTS) {
      if (this.#cachedWidth >= minWidth) {
        return name;
      }
    }

    return 'xs';
  }

  #initializeObserver() {
    if (this.#observer) return;

    const container = this.#getMainContainer();

    if (container) {
      this.#observer = new ResizeObserver(([{ contentRect }]) => {
        this.#handleWidthUpdate(contentRect.width);
      });
      this.#observer.observe(container);
    } else {
      window.addEventListener('resize', () => {
        this.#handleWidthUpdate(window.innerWidth);
      });
    }
  }

  #handleWidthUpdate(newWidth) {
    const oldWidth = this.#cachedWidth;
    if (newWidth === this.#cachedWidth) return;
    this.#cachedWidth = newWidth;

    const newBreakpoint = this.#calculateBreakpoint();
    const breakpointChanged = newBreakpoint !== this.#currentBreakpoint;

    if (breakpointChanged) {
      const previousBreakpoint = this.#currentBreakpoint;
      this.#currentBreakpoint = newBreakpoint;

      this.#breakpointSubscribers.forEach((callback) => {
        callback(newBreakpoint, previousBreakpoint);
      });
    }

    this.#resizeHandlers.forEach((handler) => {
      handler(newWidth, oldWidth);
    });
  }
}

export const PanelBreakpointInstance = new PanelBreakpointManager();

export { PanelBreakpointManager };
