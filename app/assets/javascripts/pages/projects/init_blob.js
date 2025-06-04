import { addShortcutsExtension } from '~/behaviors/shortcuts';
import { shortcircuitPermalinkButton } from '~/blob/utils';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import BlobForkSuggestion from '~/blob/blob_fork_suggestion';
import LineHighlighter from '~/blob/line_highlighter';

export default () => {
  new LineHighlighter(); // eslint-disable-line no-new

  shortcircuitPermalinkButton();

  addShortcutsExtension(ShortcutsNavigation);

  new BlobForkSuggestion({
    openButtons: document.querySelectorAll('.js-edit-blob-link-fork-toggler'),
    forkButtons: document.querySelectorAll('.js-fork-suggestion-button'),
    cancelButtons: document.querySelectorAll('.js-cancel-fork-suggestion-button'),
    suggestionSections: document.querySelectorAll('.js-file-fork-suggestion-section'),
    actionTextPieces: document.querySelectorAll('.js-file-fork-suggestion-section-action'),
  }).init();
};
