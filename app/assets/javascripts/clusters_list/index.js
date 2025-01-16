import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import ClustersMainView from './components/clusters_main_view.vue';
import { createStore } from './store';

Vue.use(GlToast);
Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('.js-clusters-main-view');

  if (!el) {
    return null;
  }

  const defaultClient = createDefaultClient();

  const {
    emptyStateImage,
    defaultBranchName,
    projectPath,
    kasAddress,
    addClusterPath,
    newClusterDocsPath,
    emptyStateHelpText,
    clustersEmptyStateImage,
    canAddCluster,
    canAdminCluster,
    kasInstallVersion,
    displayClusterAgents,
    certificateBasedClustersEnabled,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider: new VueApollo({ defaultClient }),
    provide: {
      emptyStateImage,
      projectPath,
      kasAddress,
      addClusterPath,
      newClusterDocsPath,
      emptyStateHelpText,
      clustersEmptyStateImage,
      canAddCluster: parseBoolean(canAddCluster),
      canAdminCluster: parseBoolean(canAdminCluster),
      kasInstallVersion,
      displayClusterAgents: parseBoolean(displayClusterAgents),
      certificateBasedClustersEnabled: parseBoolean(certificateBasedClustersEnabled),
    },
    store: createStore(el.dataset),
    render(createElement) {
      return createElement(ClustersMainView, {
        props: {
          defaultBranchName,
        },
      });
    },
  });
};
