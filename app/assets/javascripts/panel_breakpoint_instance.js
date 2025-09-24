let observer = null;
let handlers = [];
let prevWidth = 0;

/**
 * PanelBreakPointInstance is a panel friendly port of GlBreakpointInstance.
 *
 * It provides an implementation of `getBreakpointSize` to return the current container breakpoint
 * with a fallback to window, when panels are not used.
 */
const MAIN_CONTAINER_SELECTOR =
  '.js-static-panel-inner #content-body, .js-container-queries-enabled > *';

const breakpoints = {
  xl: 1200,
  lg: 992,
  md: 768,
  sm: 576,
  xs: 0,
};

const getMainContainer = () => document.querySelector(MAIN_CONTAINER_SELECTOR);

export const PanelBreakpointInstance = {
  windowWidth: () => window.innerWidth,

  availableWidth: () => {
    if (getMainContainer()) {
      return getMainContainer().clientWidth;
    }
    return window.innerWidth;
  },

  addResizeListener: (handler) => {
    if (getMainContainer()) {
      handlers = [...handlers, handler];

      if (!observer) {
        prevWidth = getMainContainer()?.clientWidth;
        const callback = (entries) => {
          entries.forEach((e) => {
            const width = getMainContainer()?.clientWidth;
            if (typeof width === 'number' && width !== prevWidth) {
              prevWidth = width;
              handlers.forEach((currentHandler) => currentHandler(e));
            }
          });
        };

        observer = new ResizeObserver(callback);
        observer.observe(getMainContainer());
      }
    } else {
      window.addEventListener('resize', handler);
    }
  },

  removeResizeListener: (handler) => {
    if (getMainContainer()) {
      handlers = handlers.filter((h) => {
        return h !== handler;
      });

      if (handlers.length === 0) {
        observer.disconnect();
        observer = null;
      }
    } else {
      window.removeEventListener('resize', handler);
    }
  },

  getBreakpointSize() {
    const availableWidth = this.availableWidth();

    const breakpoint = Object.keys(breakpoints).find((key) => availableWidth >= breakpoints[key]);
    return breakpoint;
  },

  isDesktop() {
    return ['xl', 'lg'].includes(this.getBreakpointSize());
  },
};
