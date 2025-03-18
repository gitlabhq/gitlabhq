import { parseNamespaceProvideData } from 'ee_else_ce/usage_quotas/storage/namespace/utils';
import { getStorageTabMetadata } from '../utils';
import NamespaceStorageApp from './components/namespace_storage_app.vue';

export const getNamespaceStorageTabMetadata = ({ customApolloProvider } = {}) => {
  return getStorageTabMetadata({
    vueComponent: NamespaceStorageApp,
    parseProvideData: parseNamespaceProvideData,
    customApolloProvider,
  });
};
