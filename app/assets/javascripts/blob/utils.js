import { getBaseURL } from '~/lib/utils/url_utility';

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

export default () => ({});
