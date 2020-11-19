import Vuex from 'vuex';
import userLists from '../gitlab_user_list';
import state from './state';
import * as actions from './actions';
import mutations from './mutations';

export default data =>
  new Vuex.Store({
    actions,
    mutations,
    state: state(data),
    modules: {
      userLists: userLists(data),
    },
  });
