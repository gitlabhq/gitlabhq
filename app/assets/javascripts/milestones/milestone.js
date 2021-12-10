import createFlash from '~/flash';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { historyPushState } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { GlTabsBehavior, TAB_SHOWN_EVENT } from '~/tabs';

export default class Milestone {
  constructor() {
    this.tabsEl = document.querySelector('.js-milestone-tabs');
    this.glTabs = new GlTabsBehavior(this.tabsEl);
    this.loadedTabs = new WeakSet();

    this.bindTabsSwitching();
    this.loadInitialTab();
  }

  bindTabsSwitching() {
    this.tabsEl.addEventListener(TAB_SHOWN_EVENT, (event) => {
      const tab = event.target;
      const { activeTabPanel } = event.detail;
      historyPushState(tab.getAttribute('href'));
      this.loadTab(tab, activeTabPanel);
    });
  }

  loadInitialTab() {
    const tab = this.tabsEl.querySelector(`a[href="${window.location.hash}"]`);
    this.glTabs.activateTab(tab || this.glTabs.activeTab);
  }
  loadTab(tab, tabPanel) {
    const { endpoint } = tab.dataset;

    if (endpoint && !this.loadedTabs.has(tab)) {
      axios
        .get(endpoint)
        .then(({ data }) => {
          // eslint-disable-next-line no-param-reassign
          tabPanel.innerHTML = sanitize(data.html);
          this.loadedTabs.add(tab);
        })
        .catch(() =>
          createFlash({
            message: __('Error loading milestone tab'),
          }),
        );
    }
  }
}
