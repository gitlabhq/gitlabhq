import {
  updateHistory,
  urlIsDifferent,
  urlContainsSha,
  getShaFromUrl,
} from '~/lib/utils/url_utility';
import { updateRefPortionOfTitle } from '~/repository/utils/title';

export function moveToFilePermalink() {
  const fileBlobPermalinkUrlElement = document.querySelector('.js-data-file-blob-permalink-url');
  const permalink = fileBlobPermalinkUrlElement?.getAttribute('href');

  if (!permalink) {
    return;
  }

  if (urlIsDifferent(permalink)) {
    updateHistory({
      url: permalink,
      title: document.title,
    });

    if (urlContainsSha({ url: permalink })) {
      updateRefPortionOfTitle(getShaFromUrl({ url: permalink }));
    }
  }
}

function eventHasModifierKeys(event) {
  // We ignore alt because I don't think alt clicks normally do anything special?
  return event.ctrlKey || event.metaKey || event.shiftKey;
}

export function shortcircuitPermalinkButton() {
  const fileBlobPermalinkUrlElement = document.querySelector('.js-data-file-blob-permalink-url');

  fileBlobPermalinkUrlElement?.addEventListener('click', (e) => {
    if (!eventHasModifierKeys(e)) {
      e.preventDefault();
      moveToFilePermalink();
    }
  });
}

const MARKDOWN_EXTENSIONS = ['md', 'markdown', 'mkd', 'mkdn', 'mdown', 'rmd'];

export const isMarkdownFilePath = (path) =>
  MARKDOWN_EXTENSIONS.some((ext) => path?.toLowerCase().endsWith(`.${ext}`));

export default () => ({});
