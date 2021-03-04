import $ from 'jquery';
import OAuthRememberMe from '~/pages/sessions/new/oauth_remember_me';

describe('OAuthRememberMe', () => {
  const findFormAction = (selector) => {
    return $(`#oauth-container .oauth-login${selector}`).parent('form').attr('action');
  };

  beforeEach(() => {
    loadFixtures('static/oauth_remember_me.html');

    new OAuthRememberMe({ container: $('#oauth-container') }).bindEvents();
  });

  it('adds the "remember_me" query parameter to all OAuth login buttons', () => {
    $('#oauth-container #remember_me').click();

    expect(findFormAction('.twitter')).toBe('http://example.com/?remember_me=1');
    expect(findFormAction('.github')).toBe('http://example.com/?remember_me=1');
    expect(findFormAction('.facebook')).toBe(
      'http://example.com/?redirect_fragment=L1&remember_me=1',
    );
  });

  it('removes the "remember_me" query parameter from all OAuth login buttons', () => {
    $('#oauth-container #remember_me').click();
    $('#oauth-container #remember_me').click();

    expect(findFormAction('.twitter')).toBe('http://example.com/');
    expect(findFormAction('.github')).toBe('http://example.com/');
    expect(findFormAction('.facebook')).toBe('http://example.com/?redirect_fragment=L1');
  });
});
