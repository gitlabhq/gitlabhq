import { __ } from '~/locale';
import ImportUsageApp from './components/import_usage_app.vue';

export const getImportTabMetadata = () => {
  const el = document.querySelector('#js-import-usage-app');

  if (!el) return false;

  const { placeholderUsersCount, placeholderUsersLimit } = el.dataset;

  const provide = {
    placeholderUsersCount: parseInt(placeholderUsersCount, 10),
    placeholderUsersLimit: parseInt(placeholderUsersLimit, 10),
  };

  return {
    title: __('Import'),
    hash: '#import-usage-tab',
    testid: 'import-usage-tab',
    component: {
      name: 'ImportUsageTab',
      provide,
      render(createElement) {
        return createElement(ImportUsageApp);
      },
    },
  };
};
