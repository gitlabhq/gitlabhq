import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsBlob from '~/behaviors/shortcuts/shortcuts_blob';
import { shortcircuitPermalinkButton } from '~/blob/utils';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import BlobForkSuggestion from '~/blob/blob_fork_suggestion';
import BlobLinePermalinkUpdater from '~/blob/blob_line_permalink_updater';
import LineHighlighter from '~/blob/line_highlighter';

export default () => {
  new LineHighlighter(); // eslint-disable-line no-new

  // eslint-disable-next-line no-new
  new BlobLinePermalinkUpdater(
    document.querySelector('#blob-content-holder'),
    '.file-line-num[data-line-number], .file-line-num[data-line-number] *',
    document.querySelectorAll('.js-data-file-blob-permalink-url, .js-blob-blame-link'),
  );

  shortcircuitPermalinkButton();

  addShortcutsExtension(ShortcutsNavigation);
  addShortcutsExtension(ShortcutsBlob);

  new BlobForkSuggestion({
    openButtons: document.querySelectorAll('.js-edit-blob-link-fork-toggler'),
    forkButtons: document.querySelectorAll('.js-fork-suggestion-button'),
    cancelButtons: document.querySelectorAll('.js-cancel-fork-suggestion-button'),
    suggestionSections: document.querySelectorAll('.js-file-fork-suggestion-section'),
    actionTextPieces: document.querySelectorAll('.js-file-fork-suggestion-section-action'),
  }).init();
};
