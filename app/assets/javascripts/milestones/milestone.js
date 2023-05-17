import { createAlert } from '~/alert';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { GlTabsBehavior, TAB_SHOWN_EVENT, HISTORY_TYPE_HASH } from '~/tabs';

export default class Milestone {
  constructor() {
    this.tabsEl = document.querySelector('.js-milestone-tabs');
    this.loadedTabs = new WeakSet();

    this.bindTabsSwitching();
    // eslint-disable-next-line no-new
    new GlTabsBehavior(this.tabsEl, { history: HISTORY_TYPE_HASH });
  }

  bindTabsSwitching() {
    this.tabsEl.addEventListener(TAB_SHOWN_EVENT, (event) => {
      const tab = event.target;
      const { activeTabPanel } = event.detail;
      this.loadTab(tab, activeTabPanel);
    });
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
          createAlert({
            message: __('Error loading milestone tab'),
          }),
        );
    }
  }
}
