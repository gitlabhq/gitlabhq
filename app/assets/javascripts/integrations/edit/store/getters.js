export const isInheriting = state => (state.adminState === null ? false : !state.override);

export const isSavingOrTesting = state => state.isSaving || state.isTesting;

export const propsSource = (state, getters) =>
  getters.isInheriting ? state.adminState : state.customState;

export const currentKey = (state, getters) => (getters.isInheriting ? 'admin' : 'custom');
