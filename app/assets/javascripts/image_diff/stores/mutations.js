import * as types from './mutation_types';

export default {
  // [types.SET_IMAGES](state, images) {
  //   Object.assign(state, {
  //     images,
  //   });
  // },

  // [types.SET_COORDINATES](state, coordinates) {
  //   Object.assign(state, {
  //     coordinates,
  //   });
  // },

  [types.ADD_COORDINATE](state, data) {
    const { imageDiffId, coordinate } = data;

    state.imageDiffs[imageDiffId].coordinates.push(coordinate);
  },

  [types.ADD_IMAGE_DIFF](state, imageDiff) {
    const { id, images, coordinates } = imageDiff;

    state.imageDiffs[id] = {
      images,
      coordinates,
    };
  },
};
