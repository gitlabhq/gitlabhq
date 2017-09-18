import * as types from './mutation_types';

// export const setImages = ({ commit }, data) => commit(types.SET_IMAGES, data);
// export const setCoordinates = ({ commit }, data) => commit(types.SET_COORDINATES, data);
export const addImageDiff = ({ commit }, data) => commit(types.ADD_IMAGE_DIFF, data);
export const addCoordinate = ({ commit }, data) => commit(types.ADD_COORDINATE, data);
