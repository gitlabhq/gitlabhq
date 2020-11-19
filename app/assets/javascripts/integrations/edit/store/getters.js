export const isInheriting = state => (state.defaultState === null ? false : !state.override);

export const isDisabled = state => state.isSaving || state.isTesting || state.isResetting;

export const propsSource = (state, getters) =>
  getters.isInheriting ? state.defaultState : state.customState;

export const currentKey = (state, getters) => (getters.isInheriting ? 'admin' : 'custom');
