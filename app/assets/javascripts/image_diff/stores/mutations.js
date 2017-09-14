import * as types from './mutation_types';

export default {
  [types.SET_IMAGES](state, images) {
    Object.assign(state, {
      images,
    });
  },

  [types.SET_COORDINATES](state, coordinates) {
    Object.assign(state, {
      coordinates,
    });
  },
};
