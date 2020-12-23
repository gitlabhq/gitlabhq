import state from '~/jobs/store/state';

export const resetStore = (store) => {
  store.replaceState(state());
};
