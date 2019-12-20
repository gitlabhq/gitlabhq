import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import CreateEksCluster from './components/create_eks_cluster.vue';
import createStore from './store';

Vue.use(Vuex);

export default el => {
  const {
    gitlabManagedClusterHelpPath,
    kubernetesIntegrationHelpPath,
    accountAndExternalIdsHelpPath,
    createRoleArnHelpPath,
    externalId,
    accountId,
    instanceTypes,
    hasCredentials,
    createRolePath,
    createClusterPath,
    externalLinkIcon,
    roleArn,
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({
      initialState: {
        hasCredentials: parseBoolean(hasCredentials),
        externalId,
        accountId,
        instanceTypes: JSON.parse(instanceTypes),
        createRolePath,
        createClusterPath,
        roleArn,
      },
    }),
    components: {
      CreateEksCluster,
    },
    render(createElement) {
      return createElement('create-eks-cluster', {
        props: {
          gitlabManagedClusterHelpPath,
          kubernetesIntegrationHelpPath,
          accountAndExternalIdsHelpPath,
          createRoleArnHelpPath,
          externalLinkIcon,
        },
      });
    },
  });
};
