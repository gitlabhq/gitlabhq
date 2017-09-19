import Vue from 'vue';
import * as types from './mutation_types';

export default {
  [types.ADD_COORDINATE](state, data) {
    const { imageDiffId, coordinate } = data;

    state.imageDiffs[imageDiffId].coordinates.push(coordinate);
  },

  [types.ADD_IMAGE_DIFF](state, imageDiff) {
    const { id, images, coordinates } = imageDiff;

    Vue.set(state.imageDiffs, id, {
      images: Object.assign({}, images),
      coordinates: coordinates.slice(),
    });
  },
};
