import Cookies from 'js-cookie';
import {
  DIFF_FILE_BY_FILE_COOKIE_NAME,
  DIFF_VIEW_FILE_BY_FILE,
  DIFF_VIEW_ALL_FILES,
} from '~/diffs/constants';
import { fileByFile } from '~/diffs/utils/preferences';

describe('diffs preferences', () => {
  describe('fileByFile', () => {
    afterEach(() => {
      Cookies.remove(DIFF_FILE_BY_FILE_COOKIE_NAME);
    });

    it.each`
      result   | preference | cookie
      ${true}  | ${false}   | ${DIFF_VIEW_FILE_BY_FILE}
      ${false} | ${true}    | ${DIFF_VIEW_ALL_FILES}
      ${true}  | ${false}   | ${DIFF_VIEW_FILE_BY_FILE}
      ${false} | ${true}    | ${DIFF_VIEW_ALL_FILES}
      ${false} | ${false}   | ${DIFF_VIEW_ALL_FILES}
      ${true}  | ${true}    | ${DIFF_VIEW_FILE_BY_FILE}
    `(
      'should return $result when { preference: $preference, cookie: $cookie }',
      ({ result, preference, cookie }) => {
        Cookies.set(DIFF_FILE_BY_FILE_COOKIE_NAME, cookie);

        expect(fileByFile(preference)).toBe(result);
      },
    );
  });
});
