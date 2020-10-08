import initNotes from '~/init_notes';
import loadAwardsHandler from '~/awards_handler';
import { SnippetShowInit } from '~/snippets';
import ZenMode from '~/zen_mode';

document.addEventListener('DOMContentLoaded', () => {
  SnippetShowInit();
  initNotes();
  loadAwardsHandler();

  // eslint-disable-next-line no-new
  new ZenMode();
});
