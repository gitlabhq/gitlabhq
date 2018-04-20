import AccessorUtilities from '~/lib/utils/accessor';

/**
 * Memorize the last selected tab after reloading a page.
 * Does that setting the current selected tab in the localStorage
 */
export default class SigninTabsMemoizer {
  constructor({ currentTabKey = 'current_signin_tab', tabSelector = 'ul.new-session-tabs' } = {}) {
    this.currentTabKey = currentTabKey;
    this.tabSelector = tabSelector;
    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    // sets selected tab if given as hash tag
    if (window.location.hash) {
      this.saveData(window.location.hash);
    }

    this.bootstrap();
  }

  bootstrap() {
    const tabs = document.querySelectorAll(this.tabSelector);
    if (tabs.length > 0) {
      tabs[0].addEventListener('click', (e) => {
        if (e.target && e.target.nodeName === 'A') {
          const anchorName = e.target.getAttribute('href');
          this.saveData(anchorName);
        }
      });
    }

    this.showTab();
  }

  showTab() {
    const anchorName = this.readData();
    if (anchorName) {
      const tab = document.querySelector(`${this.tabSelector} a[href="${anchorName}"]`);
      if (tab) {
        tab.click();
      }
    }
  }

  saveData(val) {
    if (!this.isLocalStorageAvailable) return undefined;

    return window.localStorage.setItem(this.currentTabKey, val);
  }

  readData() {
    if (!this.isLocalStorageAvailable) return null;

    return window.localStorage.getItem(this.currentTabKey);
  }
}
