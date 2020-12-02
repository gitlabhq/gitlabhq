import Cookies from 'js-cookie';
import { getParameterValues } from '~/lib/utils/url_utility';

import { fileByFile } from '~/diffs/utils/preferences';
import {
  DIFF_FILE_BY_FILE_COOKIE_NAME,
  DIFF_VIEW_FILE_BY_FILE,
  DIFF_VIEW_ALL_FILES,
} from '~/diffs/constants';

jest.mock('~/lib/utils/url_utility');

describe('diffs preferences', () => {
  describe('fileByFile', () => {
    it.each`
      result   | preference | cookie                    | searchParam
      ${false} | ${false}   | ${undefined}              | ${undefined}
      ${true}  | ${true}    | ${undefined}              | ${undefined}
      ${true}  | ${false}   | ${DIFF_VIEW_FILE_BY_FILE} | ${undefined}
      ${false} | ${true}    | ${DIFF_VIEW_ALL_FILES}    | ${undefined}
      ${true}  | ${false}   | ${undefined}              | ${[DIFF_VIEW_FILE_BY_FILE]}
      ${false} | ${true}    | ${undefined}              | ${[DIFF_VIEW_ALL_FILES]}
      ${true}  | ${false}   | ${DIFF_VIEW_FILE_BY_FILE} | ${[DIFF_VIEW_FILE_BY_FILE]}
      ${true}  | ${true}    | ${DIFF_VIEW_ALL_FILES}    | ${[DIFF_VIEW_FILE_BY_FILE]}
      ${false} | ${false}   | ${DIFF_VIEW_ALL_FILES}    | ${[DIFF_VIEW_ALL_FILES]}
      ${false} | ${true}    | ${DIFF_VIEW_FILE_BY_FILE} | ${[DIFF_VIEW_ALL_FILES]}
    `(
      'should return $result when { preference: $preference, cookie: $cookie, search: $searchParam }',
      ({ result, preference, cookie, searchParam }) => {
        if (cookie) {
          Cookies.set(DIFF_FILE_BY_FILE_COOKIE_NAME, cookie);
        }

        getParameterValues.mockReturnValue(searchParam);

        expect(fileByFile(preference)).toBe(result);
      },
    );
  });
});
