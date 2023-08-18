// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import state from './state';

export default (data) =>
  new Vuex.Store({
    actions,
    mutations,
    state: state(data),
  });
