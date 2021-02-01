import Vuex from 'vuex';
import clusterDropdownStore from '~/create_cluster/store/cluster_dropdown';
import {
  fetchRoles,
  fetchKeyPairs,
  fetchVpcs,
  fetchSubnets,
  fetchSecurityGroups,
} from '../services/aws_services_facade';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

const createStore = ({ initialState }) =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state: Object.assign(state(), initialState),
    modules: {
      roles: {
        namespaced: true,
        ...clusterDropdownStore({ fetchFn: fetchRoles }),
      },
      keyPairs: {
        namespaced: true,
        ...clusterDropdownStore({ fetchFn: fetchKeyPairs }),
      },
      vpcs: {
        namespaced: true,
        ...clusterDropdownStore({ fetchFn: fetchVpcs }),
      },
      subnets: {
        namespaced: true,
        ...clusterDropdownStore({ fetchFn: fetchSubnets }),
      },
      securityGroups: {
        namespaced: true,
        ...clusterDropdownStore({ fetchFn: fetchSecurityGroups }),
      },
      instanceTypes: {
        namespaced: true,
        ...clusterDropdownStore({ initialState: { items: initialState.instanceTypes } }),
      },
    },
  });

export default createStore;
