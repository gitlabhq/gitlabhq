import state from '~/releases/stores/modules/index/state';

export const resetStore = (store) => {
  store.replaceState(state());
};
