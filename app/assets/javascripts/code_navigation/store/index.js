// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import actions from './actions';
import mutations from './mutations';
import createState from './state';

export default () =>
  new Vuex.Store({
    actions,
    mutations,
    state: createState(),
  });
