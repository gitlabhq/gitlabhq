import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import actionsFactory from '~/vue_shared/components/metric_images/store/actions';
import * as types from '~/vue_shared/components/metric_images/store/mutation_types';
import createStore from '~/vue_shared/components/metric_images/store';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { fileList, initialData } from '../mock_data';

jest.mock('~/alert');
const service = {
  getMetricImages: jest.fn(),
  uploadMetricImage: jest.fn(),
  updateMetricImage: jest.fn(),
  deleteMetricImage: jest.fn(),
};

const actions = actionsFactory(service);

const defaultState = {
  issueIid: 1,
  projectId: '2',
};

Vue.use(Vuex);

describe('Metrics tab store actions', () => {
  let store;
  let state;

  beforeEach(() => {
    store = createStore(defaultState);
    state = store.state;
  });

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('fetching metric images', () => {
    it('should call success action when fetching metric images', () => {
      service.getMetricImages.mockImplementation(() => Promise.resolve(fileList));

      return testAction(actions.fetchImages, null, state, [
        { type: types.REQUEST_METRIC_IMAGES },
        {
          type: types.RECEIVE_METRIC_IMAGES_SUCCESS,
          payload: convertObjectPropsToCamelCase(fileList, { deep: true }),
        },
      ]);
    });

    it('should call error action when fetching metric images with an error', async () => {
      service.getMetricImages.mockImplementation(() => Promise.reject());

      await testAction(
        actions.fetchImages,
        null,
        state,
        [{ type: types.REQUEST_METRIC_IMAGES }, { type: types.RECEIVE_METRIC_IMAGES_ERROR }],
        [],
      );
      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('uploading metric images', () => {
    const payload = {
      // mock the FileList api
      files: {
        item() {
          return fileList[0];
        },
      },
      url: 'test_url',
    };

    it('should call success action when uploading an image', () => {
      service.uploadMetricImage.mockImplementation(() => Promise.resolve(fileList[0]));

      return testAction(actions.uploadImage, payload, state, [
        { type: types.REQUEST_METRIC_UPLOAD },
        {
          type: types.RECEIVE_METRIC_UPLOAD_SUCCESS,
          payload: fileList[0],
        },
      ]);
    });

    it('should call error action when failing to upload an image', async () => {
      service.uploadMetricImage.mockImplementation(() => Promise.reject());

      await testAction(
        actions.uploadImage,
        payload,
        state,
        [{ type: types.REQUEST_METRIC_UPLOAD }, { type: types.RECEIVE_METRIC_UPLOAD_ERROR }],
        [],
      );
      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('updating metric images', () => {
    const payload = {
      url: 'test_url',
      urlText: 'url text',
    };

    it('should call success action when updating an image', () => {
      service.updateMetricImage.mockImplementation(() => Promise.resolve());

      return testAction(actions.updateImage, payload, state, [
        { type: types.REQUEST_METRIC_UPLOAD },
        {
          type: types.RECEIVE_METRIC_UPDATE_SUCCESS,
        },
      ]);
    });

    it('should call error action when failing to update an image', async () => {
      service.updateMetricImage.mockImplementation(() => Promise.reject());

      await testAction(
        actions.updateImage,
        payload,
        state,
        [{ type: types.REQUEST_METRIC_UPLOAD }, { type: types.RECEIVE_METRIC_UPLOAD_ERROR }],
        [],
      );
      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('deleting a metric image', () => {
    const payload = fileList[0].id;

    it('should call success action when deleting an image', () => {
      service.deleteMetricImage.mockImplementation(() => Promise.resolve());

      return testAction(actions.deleteImage, payload, state, [
        {
          type: types.RECEIVE_METRIC_DELETE_SUCCESS,
          payload,
        },
      ]);
    });
  });

  describe('initial data', () => {
    it('should set the initial data correctly', () => {
      return testAction(actions.setInitialData, initialData, state, [
        { type: types.SET_INITIAL_DATA, payload: initialData },
      ]);
    });
  });
});
