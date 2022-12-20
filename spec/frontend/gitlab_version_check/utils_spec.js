import { parseBoolean, getCookie, setCookie } from '~/lib/utils/common_utils';
import { getHideAlertModalCookie, setHideAlertModalCookie } from '~/gitlab_version_check/utils';
import { COOKIE_EXPIRATION, COOKIE_SUFFIX } from '~/gitlab_version_check/constants';

jest.mock('~/lib/utils/common_utils', () => ({
  parseBoolean: jest.fn().mockReturnValue(true),
  getCookie: jest.fn().mockReturnValue('true'),
  setCookie: jest.fn(),
}));

describe('GitLab Version Check Utils', () => {
  describe('setHideAlertModalCookie', () => {
    it('properly generates a key based on the currentVersion and sets Cookie to `true`', () => {
      const currentVersion = '99.9.9';

      setHideAlertModalCookie(currentVersion);

      expect(setCookie).toHaveBeenCalledWith(`${currentVersion}${COOKIE_SUFFIX}`, true, {
        expires: COOKIE_EXPIRATION,
      });
    });
  });

  describe('getHideAlertModalCookie', () => {
    it('properly generates a key based on the currentVersion, fetches said Cooke, and parsesBoolean it', () => {
      const currentVersion = '99.9.9';

      const res = getHideAlertModalCookie(currentVersion);

      expect(getCookie).toHaveBeenCalledWith(`${currentVersion}${COOKIE_SUFFIX}`);
      expect(parseBoolean).toHaveBeenCalledWith('true');
      expect(res).toBe(true);
    });
  });
});
