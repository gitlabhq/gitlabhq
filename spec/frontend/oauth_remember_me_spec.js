import $ from 'jquery';
import { loadHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import OAuthRememberMe from '~/pages/sessions/new/oauth_remember_me';

describe('OAuthRememberMe', () => {
  const findFormAction = (selector) => {
    return $(`#oauth-container .js-oauth-login${selector}`).parent('form').attr('action');
  };

  beforeEach(() => {
    loadHTMLFixture('static/oauth_remember_me.html');

    new OAuthRememberMe({ container: $('#oauth-container') }).bindEvents();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('adds and removes the "remember_me" query parameter from all OAuth login buttons', () => {
    $('#oauth-container #remember_me_omniauth').click();

    expect(findFormAction('.twitter')).toBe('http://example.com/?remember_me=1');
    expect(findFormAction('.github')).toBe('http://example.com/?remember_me=1');
    expect(findFormAction('.facebook')).toBe(
      'http://example.com/?redirect_fragment=L1&remember_me=1',
    );

    $('#oauth-container #remember_me_omniauth').click();

    expect(findFormAction('.twitter')).toBe('http://example.com/');
    expect(findFormAction('.github')).toBe('http://example.com/');
    expect(findFormAction('.facebook')).toBe('http://example.com/?redirect_fragment=L1');
  });
});
