import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

import clusterDropdownStore from './cluster_dropdown';

import {
  fetchRoles,
  fetchRegions,
  fetchKeyPairs,
  fetchVpcs,
  fetchSubnets,
  fetchSecurityGroups,
} from '../services/aws_services_facade';

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
      regions: {
        namespaced: true,
        ...clusterDropdownStore({ fetchFn: fetchRegions }),
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
