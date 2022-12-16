import store from '~/mr_notes/stores';

export function initOverviewTabCounter() {
  const discussionsCount = document.querySelector('.js-discussions-count');
  store.watch(
    (state, getters) => getters.discussionTabCounter,
    (val) => {
      if (typeof val !== 'undefined') {
        discussionsCount.textContent = val;
      }
    },
  );
}
