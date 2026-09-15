import { applyDeepLinkFragment } from '~/authentication/sessions/post_signin_fragment';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('post_signin_fragment', () => {
  beforeEach(() => {
    setWindowLocation('https://gitlab.test/users/sign_in');
  });

  describe('applyDeepLinkFragment', () => {
    it('appends the address-bar fragment to the url', () => {
      setWindowLocation('https://gitlab.test/users/sign_in#L7');

      expect(applyDeepLinkFragment('/users/sign_in')).toBe('/users/sign_in#L7');
    });

    it('returns the url unchanged when there is no fragment', () => {
      expect(applyDeepLinkFragment('/users/sign_in')).toBe('/users/sign_in');
    });

    it('replaces an existing fragment on the url', () => {
      setWindowLocation('https://gitlab.test/users/sign_in#L7');

      expect(applyDeepLinkFragment('/users/sign_in#old')).toBe('/users/sign_in#L7');
    });

    it('returns the url unchanged when it is empty', () => {
      setWindowLocation('https://gitlab.test/users/sign_in#L7');

      expect(applyDeepLinkFragment('')).toBe('');
    });
  });
});
