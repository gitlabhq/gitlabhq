import { useNotes } from '~/notes/store/legacy_notes';

export function initOverviewTabCounter() {
  const discussionsCount = document.querySelector('.js-discussions-count');

  const store = useNotes();
  let counter = parseInt(discussionsCount.textContent, 10);
  store.$subscribe(() => {
    const newCounter = store.discussionTabCounter;
    if (counter !== newCounter) {
      counter = newCounter;
      discussionsCount.textContent = newCounter;
    }
  });
}
