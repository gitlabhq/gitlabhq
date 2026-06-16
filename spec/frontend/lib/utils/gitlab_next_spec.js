import { GITLAB_NEXT_COOKIE, isGitlabNextEnabled, setGitlabNext } from '~/lib/utils/gitlab_next';
import { setCookie, removeCookie, getCookie } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils', () => ({
  setCookie: jest.fn(),
  removeCookie: jest.fn(),
  getCookie: jest.fn(),
}));

describe('GitLab Next utils', () => {
  const cookieOptions = { domain: '.gitlab.com', path: '/' };

  describe('isGitlabNextEnabled', () => {
    describe('when the canary cookie is "true"', () => {
      beforeEach(() => {
        getCookie.mockReturnValue('true');
      });

      it('returns true', () => {
        expect(isGitlabNextEnabled()).toBe(true);
        expect(getCookie).toHaveBeenCalledWith(GITLAB_NEXT_COOKIE);
      });
    });

    describe('when the canary cookie is not set', () => {
      beforeEach(() => {
        getCookie.mockReturnValue(undefined);
      });

      it('returns false', () => {
        expect(isGitlabNextEnabled()).toBe(false);
      });
    });
  });

  describe('setGitlabNext', () => {
    describe('when enabling', () => {
      beforeEach(() => {
        setGitlabNext(true);
      });

      it('sets the canary cookie on the root domain', () => {
        expect(setCookie).toHaveBeenCalledWith(GITLAB_NEXT_COOKIE, 'true', cookieOptions);
        expect(removeCookie).not.toHaveBeenCalled();
      });
    });

    describe('when disabling', () => {
      beforeEach(() => {
        setGitlabNext(false);
      });

      it('removes both the .gitlab.com-scoped and legacy host-only cookies', () => {
        expect(removeCookie).toHaveBeenCalledWith(GITLAB_NEXT_COOKIE, cookieOptions);
        expect(removeCookie).toHaveBeenCalledWith(GITLAB_NEXT_COOKIE, { path: '/' });
        expect(setCookie).not.toHaveBeenCalled();
      });
    });
  });
});
