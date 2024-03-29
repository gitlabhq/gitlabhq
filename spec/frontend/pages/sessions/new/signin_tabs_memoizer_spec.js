import htmlStaticSigninTabs from 'test_fixtures_static/signin_tabs.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import AccessorUtilities from '~/lib/utils/accessor';
import SigninTabsMemoizer from '~/pages/sessions/new/signin_tabs_memoizer';
import { GlTabsBehavior } from '~/tabs';

jest.mock('~/tabs');

useLocalStorageSpy();

describe('SigninTabsMemoizer', () => {
  const tabSelector = '#js-signin-tabs';
  const currentTabKey = 'current_signin_tab';
  let memo;

  function createMemoizer() {
    memo = new SigninTabsMemoizer({
      currentTabKey,
      tabSelector,
    });
    return memo;
  }

  beforeEach(() => {
    setHTMLFixture(htmlStaticSigninTabs);

    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
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
    createMemoizer().saveData('#login-pane');
    const tab = document.querySelector(`${tabSelector} a[href="#login-pane"]`);
    jest.spyOn(tab, 'click');

    memo.bootstrap();

    expect(tab.click).toHaveBeenCalled();
  });

  it('clicks the first tab if value in local storage is bad', () => {
    createMemoizer().saveData('#bogus');
    const tab = document.querySelector(`${tabSelector} a[href="#ldap"]`);
    jest.spyOn(tab, 'click');

    memo.bootstrap();

    expect(tab.click).toHaveBeenCalled();
  });

  it('saves last selected tab on change', () => {
    createMemoizer();

    document.querySelector('a[href="#login-pane"]').click();

    expect(memo.readData()).toEqual('#login-pane');
  });

  it('overrides last selected tab with hash tag when given', () => {
    window.location.hash = '#ldap';
    createMemoizer();

    expect(memo.readData()).toEqual('#ldap');
  });

  describe('class constructor', () => {
    beforeEach(() => {
      memo = createMemoizer();
    });

    it('should set .isLocalStorageAvailable', () => {
      expect(AccessorUtilities.canUseLocalStorage).toHaveBeenCalled();
      expect(memo.isLocalStorageAvailable).toBe(true);
    });
  });

  describe('saveData', () => {
    beforeEach(() => {
      memo = {
        currentTabKey,
      };
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        memo.isLocalStorageAvailable = false;

        SigninTabsMemoizer.prototype.saveData.call(memo);
      });

      it('should not call .setItem', () => {
        expect(localStorage.setItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      const value = 'value';

      beforeEach(() => {
        memo.isLocalStorageAvailable = true;

        SigninTabsMemoizer.prototype.saveData.call(memo, value);
      });

      it('should call .setItem', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith(currentTabKey, value);
      });
    });
  });

  describe('readData', () => {
    const itemValue = 'itemValue';
    let readData;

    beforeEach(() => {
      memo = {
        currentTabKey,
      };

      localStorage.getItem.mockReturnValue(itemValue);
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        memo.isLocalStorageAvailable = false;

        readData = SigninTabsMemoizer.prototype.readData.call(memo);
      });

      it('should not call .getItem and should return `null`', () => {
        expect(localStorage.getItem).not.toHaveBeenCalled();
        expect(readData).toBe(null);
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        memo.isLocalStorageAvailable = true;

        readData = SigninTabsMemoizer.prototype.readData.call(memo);
      });

      it('should call .getItem and return the localStorage value', () => {
        expect(window.localStorage.getItem).toHaveBeenCalledWith(currentTabKey);
        expect(readData).toBe(itemValue);
      });
    });
  });
});
