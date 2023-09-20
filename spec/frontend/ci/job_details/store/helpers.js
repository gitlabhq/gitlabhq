import state from '~/ci/job_details/store/state';

export const resetStore = (store) => {
  store.replaceState(state());
};
