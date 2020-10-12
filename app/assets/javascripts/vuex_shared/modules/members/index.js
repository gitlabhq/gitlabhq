import createState from 'ee_else_ce/vuex_shared/modules/members/state';

export default initialState => ({
  namespaced: true,
  state: createState(initialState),
});
