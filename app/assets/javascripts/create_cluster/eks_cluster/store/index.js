import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

import clusterDropdownStore from './cluster_dropdown';

import * as awsServices from '../services/aws_services_facade';

const createStore = () =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state: state(),
    modules: {
      regions: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchRegions),
      },
      vpcs: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchVpcs),
      },
      subnets: {
        namespaced: true,
        ...clusterDropdownStore(awsServices.fetchSubnets),
      },
    },
  });

export default createStore;
