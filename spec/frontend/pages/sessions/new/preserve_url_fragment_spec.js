import htmlSessionsNew from 'test_fixtures/sessions/new.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  appendUrlFragment,
  appendRedirectQuery,
  toggleRememberMeQuery,
} from '~/pages/sessions/new/preserve_url_fragment';

describe('preserve_url_fragment', () => {
  beforeEach(() => {
    setHTMLFixture(htmlSessionsNew);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('non-OAuth login forms', () => {
    describe('appendUrlFragment', () => {
      const findFormAction = () => document.querySelector('.js-non-oauth-login form').action;

      it('adds the url fragment to the login form actions', () => {
        appendUrlFragment('#L65');

        expect(findFormAction()).toBe('http://test.host/users/sign_in#L65');
      });

      it('does not add an empty url fragment to the login form actions', () => {
        appendUrlFragment();

        expect(findFormAction()).toBe('http://test.host/users/sign_in');
      });
    });
  });

  describe('OAuth login forms', () => {
    const findFormAction = (selector) =>
      document.querySelector(`.js-oauth-login [data-testid=${selector}-login-button]`).parentElement
        .action;

    describe('appendRedirectQuery', () => {
      it('does not add an empty query parameter to the login form actions', () => {
        appendRedirectQuery();

        expect(findFormAction('github')).toBe('http://test.host/users/auth/github');
      });

      describe('adds "redirect_fragment" query parameter to the login form actions', () => {
        it('when "remember_me" is not present', () => {
          appendRedirectQuery('#L65');

          expect(findFormAction('github')).toBe(
            'http://test.host/users/auth/github?redirect_fragment=L65',
          );
        });

        it('when "remember_me" is present', () => {
          document
            .querySelectorAll('form')
            .forEach((form) => form.setAttribute('action', `${form.action}?remember_me=1`));

          appendRedirectQuery('#L65');

          expect(findFormAction('github')).toBe(
            'http://test.host/users/auth/github?remember_me=1&redirect_fragment=L65',
          );
        });
      });
    });

    describe('toggleRememberMeQuery', () => {
      const rememberMe = () => document.querySelector('#js-remember-me-omniauth');

      it('toggles "remember_me" query parameter', () => {
        toggleRememberMeQuery();

        expect(findFormAction('github')).toBe('http://test.host/users/auth/github');

        rememberMe().click();

        expect(findFormAction('github')).toBe('http://test.host/users/auth/github?remember_me=1');

        rememberMe().click();

        expect(findFormAction('github')).toBe('http://test.host/users/auth/github');
      });
    });
  });
});
