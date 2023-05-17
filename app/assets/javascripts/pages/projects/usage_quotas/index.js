import initProjectStorage from '~/usage_quotas/storage/init_project_storage';
import initSearchSettings from '~/search_settings';
import { GlTabsBehavior, HISTORY_TYPE_HASH } from '~/tabs';

const initGlTabs = () => {
  const tabsEl = document.getElementById('js-project-usage-quotas-tabs');
  if (!tabsEl) {
    return;
  }

  // eslint-disable-next-line no-new
  new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
};

const initVueApp = () => {
  initProjectStorage('js-project-storage-count-app');
};

initGlTabs();
initVueApp();
initSearchSettings();
