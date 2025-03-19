import { createAsyncTabContentWrapper } from '~/usage_quotas/components/async_tab_content_wrapper';
import { getStorageTabMetadata } from '../utils';
import { parseProjectProvideData } from './utils';

export const getProjectStorageTabMetadata = () => {
  const ProjectStorageApp = () => {
    const component = import(
      /* webpackChunkName: 'uq_storage_project' */ './components/project_storage_app.vue'
    );
    return createAsyncTabContentWrapper(component);
  };

  return getStorageTabMetadata({
    vueComponent: ProjectStorageApp,
    parseProvideData: parseProjectProvideData,
  });
};
