export const breakpoints = {
  lg: 1200,
  md: 992,
  sm: 768,
  xs: 0,
};

const BreakpointInstance = {
  windowWidth: () => window.innerWidth,
  getBreakpointSize() {
    const windowWidth = this.windowWidth();

    const breakpoint = Object.keys(breakpoints).find(key => windowWidth > breakpoints[key]);

    return breakpoint;
  },
};

// For legacy reasons, this is added to window
// one day this should be deleted
window.bp = BreakpointInstance;

export default BreakpointInstance;
