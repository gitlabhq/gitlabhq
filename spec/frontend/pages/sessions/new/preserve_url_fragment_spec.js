import $ from 'jquery';
import preserveUrlFragment from '~/pages/sessions/new/preserve_url_fragment';

describe('preserve_url_fragment', () => {
  preloadFixtures('sessions/new.html');

  beforeEach(() => {
    loadFixtures('sessions/new.html');
  });

  it('adds the url fragment to all login and sign up form actions', () => {
    preserveUrlFragment('#L65');

    expect($('#new_user').attr('action')).toBe('http://test.host/users/sign_in#L65');
    expect($('#new_new_user').attr('action')).toBe('http://test.host/users#L65');
  });

  it('does not add an empty url fragment to login and sign up form actions', () => {
    preserveUrlFragment();

    expect($('#new_user').attr('action')).toBe('http://test.host/users/sign_in');
    expect($('#new_new_user').attr('action')).toBe('http://test.host/users');
  });

  it('does not add an empty query parameter to OmniAuth login buttons', () => {
    preserveUrlFragment();

    expect($('#oauth-login-cas3').attr('href')).toBe('http://test.host/users/auth/cas3');

    expect($('.omniauth-container #oauth-login-auth0').attr('href')).toBe(
      'http://test.host/users/auth/auth0',
    );
  });

  describe('adds "redirect_fragment" query parameter to OmniAuth login buttons', () => {
    it('when "remember_me" is not present', () => {
      preserveUrlFragment('#L65');

      expect($('#oauth-login-cas3').attr('href')).toBe(
        'http://test.host/users/auth/cas3?redirect_fragment=L65',
      );

      expect($('.omniauth-container #oauth-login-auth0').attr('href')).toBe(
        'http://test.host/users/auth/auth0?redirect_fragment=L65',
      );
    });

    it('when "remember-me" is present', () => {
      $('a.omniauth-btn').attr('href', (i, href) => `${href}?remember_me=1`);
      preserveUrlFragment('#L65');

      expect($('#oauth-login-cas3').attr('href')).toBe(
        'http://test.host/users/auth/cas3?remember_me=1&redirect_fragment=L65',
      );

      expect($('#oauth-login-auth0').attr('href')).toBe(
        'http://test.host/users/auth/auth0?remember_me=1&redirect_fragment=L65',
      );
    });
  });
});
