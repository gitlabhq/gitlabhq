export const isAliveView = (state) => (view) =>
  state.keepAliveViews[view] || (state.isOpen && state.currentView === view);
