import { parseNamespaceProvideData } from 'ee_else_ce/usage_quotas/storage/namespace/utils';
import { createAsyncTabContentWrapper } from '~/usage_quotas/components/async_tab_content_wrapper';
import { getStorageTabMetadata } from '../utils';

export const getNamespaceStorageTabMetadata = ({ customApolloProvider } = {}) => {
  const NamespaceStorageApp = () => {
    const component = import(
      /* webpackChunkName: 'uq_storage_namespace' */ './components/namespace_storage_app.vue'
    );
    return createAsyncTabContentWrapper(component);
  };

  return getStorageTabMetadata({
    vueComponent: NamespaceStorageApp,
    parseProvideData: parseNamespaceProvideData,
    customApolloProvider,
  });
};
