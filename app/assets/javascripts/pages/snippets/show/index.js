import LineHighlighter from '../../../line_highlighter';
import BlobViewer from '../../../blob/viewer';
import ZenMode from '../../../zen_mode';
import initNotes from '../../../init_notes';

document.addEventListener('DOMContentLoaded', () => {
  new LineHighlighter(); // eslint-disable-line no-new
  new BlobViewer(); // eslint-disable-line no-new
  initNotes();
  new ZenMode(); // eslint-disable-line no-new
});
