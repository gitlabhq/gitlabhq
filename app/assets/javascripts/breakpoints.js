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

export default BreakpointInstance;
