import {
  getBaseURL,
  updateHistory,
  urlIsDifferent,
  urlContainsSha,
  getShaFromUrl,
} from '~/lib/utils/url_utility';
import { updateRefPortionOfTitle } from '~/repository/utils/title';

const blameLinesPerPage = document.querySelector('.js-per-page')?.dataset?.blamePerPage;

export const getPageParamValue = (lineNum, blamePerPage = blameLinesPerPage) => {
  if (!blamePerPage) return '';
  const page = Math.ceil(parseInt(lineNum, 10) / parseInt(blamePerPage, 10));
  return page <= 1 ? '' : page;
};

export const getPageSearchString = (path, page) => {
  if (!page) return '';
  const url = new URL(path, getBaseURL());
  url.searchParams.set('page', page);
  return url.search;
};

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

export default () => ({});
