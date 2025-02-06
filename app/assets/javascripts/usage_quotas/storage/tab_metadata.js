import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { __ } from '~/locale';
import createDefaultClient from '~/lib/graphql';
import { parseNamespaceProvideData } from 'ee_else_ce/usage_quotas/storage/namespace/utils';
import { GROUP_VIEW_TYPE, PROJECT_VIEW_TYPE, PROFILE_VIEW_TYPE } from '../constants';
import NamespaceStorageApp from './namespace/components/namespace_storage_app.vue';
import ProjectStorageApp from './project/components/project_storage_app.vue';
import { parseProjectProvideData } from './project/utils';

const getViewSpecificOptions = (viewType) => {
  if (viewType === GROUP_VIEW_TYPE || viewType === PROFILE_VIEW_TYPE) {
    return {
      vueComponent: NamespaceStorageApp,
      parseProvideData: parseNamespaceProvideData,
    };
  }

  if (viewType === PROJECT_VIEW_TYPE) {
    return {
      vueComponent: ProjectStorageApp,
      parseProvideData: parseProjectProvideData,
    };
  }

  return {};
};

export const getStorageTabMetadata = ({
  viewType = null,
  includeEl = false,
  customApolloProvider = null,
} = {}) => {
  let apolloProvider;
  const el = document.querySelector('#js-storage-usage-app');
  const { vueComponent, parseProvideData } = getViewSpecificOptions(viewType);

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
