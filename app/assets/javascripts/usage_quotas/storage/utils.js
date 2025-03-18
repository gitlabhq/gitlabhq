import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { __ } from '~/locale';
import createDefaultClient from '~/lib/graphql';

export const getStorageTabMetadata = ({
  vueComponent,
  parseProvideData,
  includeEl = false,
  customApolloProvider = null,
} = {}) => {
  let apolloProvider;
  const el = document.querySelector('#js-storage-usage-app');

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
    testid: 'storage-tab',
    component: {
      name: 'NamespaceStorageTab',
      provide: parseProvideData(el),
      apolloProvider,
      render(createElement) {
        return createElement(vueComponent);
      },
    },
  };

  if (includeEl) {
    storageTabMetadata.component.el = el;
  }

  return storageTabMetadata;
};
