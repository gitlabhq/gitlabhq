export const isActiveView = state => view => state.currentView === view;

export const isAliveView = (state, getters) => view =>
  state.keepAliveViews[view] || (state.isOpen && getters.isActiveView(view));
