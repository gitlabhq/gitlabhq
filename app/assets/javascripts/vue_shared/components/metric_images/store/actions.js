import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const fetchImagesFactory =
  (service) =>
  async ({ state, commit }) => {
    commit(types.REQUEST_METRIC_IMAGES);
    const { modelIid, projectId } = state;

    try {
      const response = await service.getMetricImages({ id: projectId, modelIid });
      commit(types.RECEIVE_METRIC_IMAGES_SUCCESS, response);
    } catch (error) {
      commit(types.RECEIVE_METRIC_IMAGES_ERROR);
      createAlert({ message: s__('MetricImages|There was an issue loading metric images.') });
    }
  };

export const uploadImageFactory =
  (service) =>
  async ({ state, commit }, { files, url, urlText }) => {
    commit(types.REQUEST_METRIC_UPLOAD);

    const { modelIid, projectId } = state;

    try {
      const response = await service.uploadMetricImage({
        file: files.item(0),
        id: projectId,
        modelIid,
        url,
        urlText,
      });
      commit(types.RECEIVE_METRIC_UPLOAD_SUCCESS, response);
    } catch (error) {
      commit(types.RECEIVE_METRIC_UPLOAD_ERROR);
      createAlert({ message: s__('MetricImages|There was an issue uploading your image.') });
    }
  };

export const updateImageFactory =
  (service) =>
  async ({ state, commit }, { imageId, url, urlText }) => {
    commit(types.REQUEST_METRIC_UPLOAD);

    const { modelIid, projectId } = state;

    try {
      const response = await service.updateMetricImage({
        modelIid,
        id: projectId,
        imageId,
        url,
        urlText,
      });
      commit(types.RECEIVE_METRIC_UPDATE_SUCCESS, response);
    } catch (error) {
      commit(types.RECEIVE_METRIC_UPLOAD_ERROR);
      createAlert({ message: s__('MetricImages|There was an issue updating your image.') });
    }
  };

export const deleteImageFactory =
  (service) =>
  async ({ state, commit }, imageId) => {
    const { modelIid, projectId } = state;

    try {
      await service.deleteMetricImage({ imageId, id: projectId, modelIid });
      commit(types.RECEIVE_METRIC_DELETE_SUCCESS, imageId);
    } catch (error) {
      createAlert({ message: s__('MetricImages|There was an issue deleting the image.') });
    }
  };

export const setInitialData = ({ commit }, data) => {
  commit(types.SET_INITIAL_DATA, data);
};

export default (service) => ({
  fetchImages: fetchImagesFactory(service),
  uploadImage: uploadImageFactory(service),
  updateImage: updateImageFactory(service),
  deleteImage: deleteImageFactory(service),
  setInitialData,
});
