import state from '~/releases/stores/modules/list/state';

export const resetStore = store => {
  store.replaceState(state());
};
