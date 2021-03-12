import $ from 'jquery';
import preserveUrlFragment from '~/pages/sessions/new/preserve_url_fragment';

describe('preserve_url_fragment', () => {
  const findFormAction = (selector) => {
    return $(`.omniauth-container ${selector}`).parent('form').attr('action');
  };

  beforeEach(() => {
    loadFixtures('sessions/new.html');
  });

  it('adds the url fragment to the login form actions', () => {
    preserveUrlFragment('#L65');

    expect($('#new_user').attr('action')).toBe('http://test.host/users/sign_in#L65');
  });

  it('does not add an empty url fragment to the login form actions', () => {
    preserveUrlFragment();

    expect($('#new_user').attr('action')).toBe('http://test.host/users/sign_in');
  });

  it('does not add an empty query parameter to OmniAuth login buttons', () => {
    preserveUrlFragment();

    expect(findFormAction('#oauth-login-cas3')).toBe('http://test.host/users/auth/cas3');

    expect(findFormAction('#oauth-login-auth0')).toBe('http://test.host/users/auth/auth0');
  });

  describe('adds "redirect_fragment" query parameter to OmniAuth login buttons', () => {
    it('when "remember_me" is not present', () => {
      preserveUrlFragment('#L65');

      expect(findFormAction('#oauth-login-cas3')).toBe(
        'http://test.host/users/auth/cas3?redirect_fragment=L65',
      );

      expect(findFormAction('#oauth-login-auth0')).toBe(
        'http://test.host/users/auth/auth0?redirect_fragment=L65',
      );
    });

    it('when "remember-me" is present', () => {
      $('.omniauth-btn')
        .parent('form')
        .attr('action', (i, href) => `${href}?remember_me=1`);

      preserveUrlFragment('#L65');

      expect(findFormAction('#oauth-login-cas3')).toBe(
        'http://test.host/users/auth/cas3?remember_me=1&redirect_fragment=L65',
      );

      expect(findFormAction('#oauth-login-auth0')).toBe(
        'http://test.host/users/auth/auth0?remember_me=1&redirect_fragment=L65',
      );
    });
  });
});
