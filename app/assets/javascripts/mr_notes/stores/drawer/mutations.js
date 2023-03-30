import types from './mutation_types';

export default {
  [types.SET_DRAWER](state, drawer) {
    Object.assign(state, { activeDrawer: drawer });
  },
};
