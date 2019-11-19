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
    getRolesPath,
    getRegionsPath,
    getKeyPairsPath,
    getVpcsPath,
    getSubnetsPath,
    getSecurityGroupsPath,
    getInstanceTypesPath,
    externalId,
    accountId,
    hasCredentials,
    createRolePath,
    createClusterPath,
    signOutPath,
    externalLinkIcon,
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({
      initialState: {
        hasCredentials: parseBoolean(hasCredentials),
        externalId,
        accountId,
        createRolePath,
        createClusterPath,
        signOutPath,
      },
      apiPaths: {
        getRolesPath,
        getRegionsPath,
        getKeyPairsPath,
        getVpcsPath,
        getSubnetsPath,
        getSecurityGroupsPath,
        getInstanceTypesPath,
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
