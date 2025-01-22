import htmlStaticSigninTabs from 'test_fixtures_static/signin_tabs.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import SigninTabsMemoizer from '~/pages/sessions/new/signin_tabs_memoizer';
import { GlTabsBehavior } from '~/tabs';

jest.mock('~/lib/utils/common_utils', () => ({
  getCookie: jest.fn(),
  setCookie: jest.fn(),
}));

jest.mock('~/tabs');

describe('SigninTabsMemoizer', () => {
  const tabSelector = '#js-signin-tabs';
  const currentTabKey = 'current_signin_tab';

  function createMemoizer() {
    new SigninTabsMemoizer(); // eslint-disable-line no-new
  }

  beforeEach(() => {
    setHTMLFixture(htmlStaticSigninTabs);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('init GlTabsBehaviour', () => {
    createMemoizer();

    expect(GlTabsBehavior).toHaveBeenCalledWith(document.querySelector(tabSelector));
  });

  it('does nothing if no tab was previously selected', () => {
    createMemoizer();

    expect(document.querySelector(`${tabSelector} > li.active a`).getAttribute('href')).toEqual(
      '#ldap',
    );
  });

  it('shows last selected tab on boot', () => {
    const tab = document.querySelector(`${tabSelector} a[href="#login-pane"]`);
    jest.spyOn(tab, 'click');
    getCookie.mockReturnValue('#login-pane');
    createMemoizer();

    expect(tab.click).toHaveBeenCalled();
  });

  it('clicks the first tab if cookie value is bad', () => {
    const tab = document.querySelector(`${tabSelector} a[href="#ldap"]`);
    jest.spyOn(tab, 'click');
    getCookie.mockReturnValue('#bogus');
    createMemoizer();

    expect(tab.click).toHaveBeenCalled();
  });

  it('saves last selected tab on click', () => {
    createMemoizer();

    document.querySelector('a[href="#login-pane"]').click();

    expect(setCookie).toHaveBeenCalledWith(currentTabKey, '#login-pane');
  });

  it('overrides last selected tab with hash tag when given', () => {
    window.location.hash = '#ldap';
    createMemoizer();

    expect(setCookie).toHaveBeenCalledWith(currentTabKey, '#ldap');
  });
});
