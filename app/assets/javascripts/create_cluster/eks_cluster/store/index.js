import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

import clusterDropdownStore from './cluster_dropdown';

import awsServicesFactory from '../services/aws_services_facade';

const createStore = ({ initialState, apiPaths }) => {
  const awsServices = awsServicesFactory(apiPaths);

  return new Vuex.Store({
    actions,
    getters,
    mutations,
    state: Object.assign(state(), initialState),
    modules: {
      roles: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchRoles),
      },
      regions: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchRegions),
      },
      keyPairs: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchKeyPairs),
      },
      vpcs: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchVpcs),
      },
      subnets: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchSubnets),
      },
      securityGroups: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchSecurityGroups),
      },
      instanceTypes: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchInstanceTypes),
      },
    },
  });
};

export default createStore;
