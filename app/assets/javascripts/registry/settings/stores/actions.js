import * as types from './mutation_types';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);

// to avoid eslint error until more actions are added to the store
export default () => {};
