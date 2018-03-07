import LineHighlighter from '~/line_highlighter';
import BlobLinePermalinkUpdater from '~/blob/blob_line_permalink_updater';
import ShortcutsNavigation from '~/shortcuts_navigation';
import ShortcutsBlob from '~/shortcuts_blob';
import BlobForkSuggestion from '~/blob/blob_fork_suggestion';
import initBlobBundle from '~/blob_edit/blob_bundle';

export default () => {
  new LineHighlighter(); // eslint-disable-line no-new

  new BlobLinePermalinkUpdater( // eslint-disable-line no-new
    document.querySelector('#blob-content-holder'),
    '.diff-line-num[data-line-number]',
    document.querySelectorAll('.js-data-file-blob-permalink-url, .js-blob-blame-link'),
  );

  const fileBlobPermalinkUrlElement = document.querySelector('.js-data-file-blob-permalink-url');
  const fileBlobPermalinkUrl = fileBlobPermalinkUrlElement && fileBlobPermalinkUrlElement.getAttribute('href');

  new ShortcutsNavigation(); // eslint-disable-line no-new

  new ShortcutsBlob({ // eslint-disable-line no-new
    skipResetBindings: true,
    fileBlobPermalinkUrl,
  });

  new BlobForkSuggestion({ // eslint-disable-line no-new
    openButtons: document.querySelectorAll('.js-edit-blob-link-fork-toggler'),
    forkButtons: document.querySelectorAll('.js-fork-suggestion-button'),
    cancelButtons: document.querySelectorAll('.js-cancel-fork-suggestion-button'),
    suggestionSections: document.querySelectorAll('.js-file-fork-suggestion-section'),
    actionTextPieces: document.querySelectorAll('.js-file-fork-suggestion-section-action'),
  }).init();

  initBlobBundle();
};
