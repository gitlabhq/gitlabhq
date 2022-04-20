import * as types from './mutation_types';

export default {
  [types.REQUEST_METRIC_IMAGES](state) {
    state.isLoadingMetricImages = true;
  },
  [types.RECEIVE_METRIC_IMAGES_SUCCESS](state, images) {
    state.metricImages = images || [];
    state.isLoadingMetricImages = false;
  },
  [types.RECEIVE_METRIC_IMAGES_ERROR](state) {
    state.isLoadingMetricImages = false;
  },
  [types.REQUEST_METRIC_UPLOAD](state) {
    state.isUploadingImage = true;
  },
  [types.RECEIVE_METRIC_UPLOAD_SUCCESS](state, image) {
    state.metricImages.push(image);
    state.isUploadingImage = false;
  },
  [types.RECEIVE_METRIC_UPLOAD_ERROR](state) {
    state.isUploadingImage = false;
  },
  [types.RECEIVE_METRIC_UPDATE_SUCCESS](state, image) {
    state.isUploadingImage = false;
    const metricIndex = state.metricImages.findIndex((img) => img.id === image.id);
    if (metricIndex >= 0) {
      state.metricImages.splice(metricIndex, 1, image);
    }
  },
  [types.RECEIVE_METRIC_DELETE_SUCCESS](state, imageId) {
    const metricIndex = state.metricImages.findIndex((image) => image.id === imageId);
    state.metricImages.splice(metricIndex, 1);
  },
  [types.SET_INITIAL_DATA](state, { modelIid, projectId }) {
    state.modelIid = modelIid;
    state.projectId = projectId;
  },
};
