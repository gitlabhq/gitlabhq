import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

import clusterDropdownStore from './cluster_dropdown';

import * as awsServices from '../services/aws_services_facade';

const createStore = ({ initialState }) =>
  new Vuex.Store({
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
    },
  });

export default createStore;
