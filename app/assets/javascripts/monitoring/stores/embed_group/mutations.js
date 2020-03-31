import * as types from './mutation_types';

export default {
  [types.ADD_MODULE](state, module) {
    state.modules.push(module);
  },
};
