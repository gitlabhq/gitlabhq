import { __ } from '~/locale';
import { createAsyncTabContentWrapper } from '../components/async_tab_content_wrapper';

export const getImportTabMetadata = () => {
  const el = document.querySelector('#js-import-usage-app');

  if (!el) return false;

  const { placeholderUsersCount, placeholderUsersLimit } = el.dataset;

  const provide = {
    placeholderUsersCount: parseInt(placeholderUsersCount, 10),
    placeholderUsersLimit: parseInt(placeholderUsersLimit, 10),
  };

  const ImportUsageApp = () => {
    const component = import(
      /* webpackChunkName: 'uq_import' */ './components/import_usage_app.vue'
    );
    return createAsyncTabContentWrapper(component);
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
