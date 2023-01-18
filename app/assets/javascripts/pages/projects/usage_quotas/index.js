import initProjectStorage from '~/usage_quotas/storage/init_project_storage';
import initSearchSettings from '~/search_settings';

const initVueApp = () => {
  initProjectStorage('js-project-storage-count-app');
};

initVueApp();
initSearchSettings();
