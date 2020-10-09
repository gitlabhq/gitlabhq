import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import mutations from './mutations';

export default data =>
  new Vuex.Store({
    actions,
    mutations,
    state: state(data),
  });
