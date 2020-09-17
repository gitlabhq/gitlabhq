import createState from './state';

export default initialState => ({
  namespaced: true,
  state: createState(initialState),
});
