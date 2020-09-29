import Vuex from 'vuex';
import createState from './state';
import actions from './actions';
import mutations from './mutations';

export default () =>
  new Vuex.Store({
    actions,
    mutations,
    state: createState(),
  });
