import { useNotes } from '~/notes/store/legacy_notes';

export function initOverviewTabCounter() {
  const discussionsCount = document.querySelector('.js-discussions-count');

  const store = useNotes();
  let counter = store.discussionTabCounter;
  store.$subscribe(() => {
    const newCounter = store.discussionTabCounter;
    if (counter !== newCounter) {
      counter = newCounter;
      discussionsCount.textContent = newCounter;
    }
  });
}
