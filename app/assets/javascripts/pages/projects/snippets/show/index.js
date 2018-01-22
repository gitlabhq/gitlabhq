import initNotes from '~/init_notes';
import ZenMode from '~/zen_mode';

export default function () {
  initNotes();
  new ZenMode(); // eslint-disable-line no-new
}
