import Cookies from 'js-cookie';
import { getParameterValues } from '~/lib/utils/url_utility';

import { DIFF_FILE_BY_FILE_COOKIE_NAME, DIFF_VIEW_FILE_BY_FILE } from '../constants';

export function fileByFile(pref = false) {
  const search = getParameterValues(DIFF_FILE_BY_FILE_COOKIE_NAME)?.[0];
  const cookie = Cookies.get(DIFF_FILE_BY_FILE_COOKIE_NAME);
  let viewFileByFile = pref;

  // use the cookie first, if it exists
  if (cookie) {
    viewFileByFile = cookie === DIFF_VIEW_FILE_BY_FILE;
  }

  // the search parameter of the URL should override, if it exists
  if (search) {
    viewFileByFile = search === DIFF_VIEW_FILE_BY_FILE;
  }

  return viewFileByFile;
}
