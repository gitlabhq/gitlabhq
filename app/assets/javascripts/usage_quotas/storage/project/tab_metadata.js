import { getStorageTabMetadata } from '../utils';
import ProjectStorageApp from './components/project_storage_app.vue';
import { parseProjectProvideData } from './utils';

export const getProjectStorageTabMetadata = () => {
  return getStorageTabMetadata({
    vueComponent: ProjectStorageApp,
    parseProvideData: parseProjectProvideData,
  });
};
