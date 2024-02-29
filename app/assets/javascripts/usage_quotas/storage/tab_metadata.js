import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { __ } from '~/locale';
import createDefaultClient from '~/lib/graphql';
import { parseProvideData } from 'ee_else_ce/usage_quotas/storage/utils';
import { STORAGE_TAB_METADATA_EL_SELECTOR } from '../constants';
import NamespaceStorageApp from './components/namespace_storage_app.vue';

export const getStorageTabMetadata = ({ includeEl = false, customApolloProvider = null } = {}) => {
  let apolloProvider;
  const el = document.querySelector(STORAGE_TAB_METADATA_EL_SELECTOR);

  if (!el) return false;

  Vue.use(VueApollo);

  if (customApolloProvider) {
    apolloProvider = customApolloProvider;
  } else {
    apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });
  }

  const storageTabMetadata = {
    title: __('Storage'),
    hash: '#storage-quota-tab',
    component: {
      name: 'NamespaceStorageTab',
      provide: parseProvideData(el),
      apolloProvider,
      render(createElement) {
        return createElement(NamespaceStorageApp);
      },
    },
  };

  if (includeEl) {
    storageTabMetadata.component.el = el;
  }

  return storageTabMetadata;
};
