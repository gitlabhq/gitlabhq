import {
  appendUrlFragment,
  appendRedirectQuery,
  toggleRememberMeQuery,
} from '~/pages/sessions/new/preserve_url_fragment';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('preserve_url_fragment', () => {
  const findAction = (testid) =>
    document.querySelector(`[data-testid="${testid}"]`).getAttribute('action');

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('appendUrlFragment', () => {
    beforeEach(() => {
      setWindowLocation('https://gitlab.test/users/sign_in#L7');
      setHTMLFixture(`
        <div class="js-non-oauth-login">
          <form action="/users/sign_in" data-testid="ldap-form"></form>
          <div id="js-sign-in-form-app">
            <form action="/users/passkeys/sign_in" data-testid="vue-form"></form>
          </div>
        </div>
      `);
    });

    it('appends the fragment to non-Vue login form actions', () => {
      appendUrlFragment();

      expect(findAction('ldap-form')).toBe('/users/sign_in#L7');
    });

    it('leaves forms rendered by the SignInForm Vue component untouched', () => {
      appendUrlFragment();

      expect(findAction('vue-form')).toBe('/users/passkeys/sign_in');
    });

    it('does nothing when there is no fragment', () => {
      setWindowLocation('https://gitlab.test/users/sign_in');

      appendUrlFragment();

      expect(findAction('ldap-form')).toBe('/users/sign_in');
    });
  });

  describe('appendRedirectQuery', () => {
    beforeEach(() => {
      setWindowLocation('https://gitlab.test/users/sign_in#L7');
      setHTMLFixture(`
        <div class="js-oauth-login">
          <form action="/users/auth/github" data-testid="oauth-form"></form>
        </div>
      `);
    });

    it('adds the fragment as a redirect_fragment query param to OAuth form actions', () => {
      appendRedirectQuery();

      expect(findAction('oauth-form')).toBe('/users/auth/github?redirect_fragment=L7');
    });

    it('does nothing when there is no fragment', () => {
      setWindowLocation('https://gitlab.test/users/sign_in');

      appendRedirectQuery();

      expect(findAction('oauth-form')).toBe('/users/auth/github');
    });
  });

  describe('toggleRememberMeQuery', () => {
    const findCheckbox = () => document.querySelector('#js-remember-me-omniauth');
    const toggleCheckbox = (checked) => {
      const checkbox = findCheckbox();
      checkbox.checked = checked;
      checkbox.dispatchEvent(new Event('change'));
    };

    beforeEach(() => {
      setHTMLFixture(`
        <div class="js-oauth-login">
          <form action="/users/auth/github" data-testid="oauth-form"></form>
        </div>
        <input type="checkbox" id="js-remember-me-omniauth" />
      `);
      toggleRememberMeQuery();
    });

    it('adds remember_me=1 to OAuth form actions when checked', () => {
      toggleCheckbox(true);

      expect(findAction('oauth-form')).toBe('/users/auth/github?remember_me=1');
    });

    it('removes remember_me from OAuth form actions when unchecked', () => {
      toggleCheckbox(true);
      toggleCheckbox(false);

      expect(findAction('oauth-form')).toBe('/users/auth/github');
    });
  });
});
