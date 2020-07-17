import * as types from './mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const setOverride = ({ commit }, override) => commit(types.SET_OVERRIDE, override);
