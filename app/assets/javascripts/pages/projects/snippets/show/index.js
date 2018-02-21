import initNotes from '~/init_notes';
import ZenMode from '~/zen_mode';
import LineHighlighter from '../../../../line_highlighter';
import BlobViewer from '../../../../blob/viewer';

document.addEventListener('DOMContentLoaded', () => {
  new LineHighlighter(); // eslint-disable-line no-new
  new BlobViewer(); // eslint-disable-line no-new
  initNotes();
  new ZenMode(); // eslint-disable-line no-new
});
