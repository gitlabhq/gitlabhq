/* eslint-disable no-new */
import LineHighlighter from '../../../line_highlighter';
import BlobViewer from '../../../blob/viewer';
import ZenMode from '../../../zen_mode';
import initNotes from '../../../init_notes';

export default () => {
  new LineHighlighter();
  new BlobViewer();
  initNotes();
  new ZenMode();
};
