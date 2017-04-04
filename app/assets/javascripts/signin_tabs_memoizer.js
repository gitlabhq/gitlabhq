/* eslint no-param-reassign: ["error", { "props": false }]*/
/* eslint no-new: "off" */
((global) => {
  /**
   * Memorize the last selected tab after reloading a page.
   * Does that setting the current selected tab in the localStorage
   */
  class ActiveTabMemoizer {
    constructor({ currentTabKey = 'current_signin_tab', tabSelector = 'ul.nav-tabs' } = {}) {
      this.currentTabKey = currentTabKey;
      this.tabSelector = tabSelector;
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
      localStorage.setItem(this.currentTabKey, val);
    }

    readData() {
      return localStorage.getItem(this.currentTabKey);
    }
  }

  global.ActiveTabMemoizer = ActiveTabMemoizer;
})(window);
