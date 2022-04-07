import { cloneDeep } from 'lodash';
import * as types from '~/vue_shared/components/metric_images/store/mutation_types';
import mutations from '~/vue_shared/components/metric_images/store/mutations';
import { initialData } from '../mock_data';

const defaultState = {
  metricImages: [],
  isLoadingMetricImages: false,
  isUploadingImage: false,
};

const testImages = [
  { filename: 'test.filename', id: 5, filePath: 'test/file/path', url: null },
  { filename: 'second.filename', id: 6, filePath: 'second/file/path', url: 'test/url' },
  { filename: 'third.filename', id: 7, filePath: 'third/file/path', url: 'test/url' },
];

describe('Metric images mutations', () => {
  let state;

  const createState = (customState = {}) => {
    state = {
      ...cloneDeep(defaultState),
      ...customState,
    };
  };

  beforeEach(() => {
    createState();
  });

  describe('REQUEST_METRIC_IMAGES', () => {
    beforeEach(() => {
      mutations[types.REQUEST_METRIC_IMAGES](state);
    });

    it('should set the loading state', () => {
      expect(state.isLoadingMetricImages).toBe(true);
    });
  });

  describe('RECEIVE_METRIC_IMAGES_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_METRIC_IMAGES_SUCCESS](state, testImages);
    });

    it('should unset the loading state', () => {
      expect(state.isLoadingMetricImages).toBe(false);
    });

    it('should set the metric images', () => {
      expect(state.metricImages).toEqual(testImages);
    });
  });

  describe('RECEIVE_METRIC_IMAGES_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_METRIC_IMAGES_ERROR](state);
    });

    it('should unset the loading state', () => {
      expect(state.isLoadingMetricImages).toBe(false);
    });
  });

  describe('REQUEST_METRIC_UPLOAD', () => {
    beforeEach(() => {
      mutations[types.REQUEST_METRIC_UPLOAD](state);
    });

    it('should set the loading state', () => {
      expect(state.isUploadingImage).toBe(true);
    });
  });

  describe('RECEIVE_METRIC_UPLOAD_SUCCESS', () => {
    const initialImage = testImages[0];
    const newImage = testImages[1];

    beforeEach(() => {
      createState({ metricImages: [initialImage] });
      mutations[types.RECEIVE_METRIC_UPLOAD_SUCCESS](state, newImage);
    });

    it('should unset the loading state', () => {
      expect(state.isUploadingImage).toBe(false);
    });

    it('should add the new metric image after the existing one', () => {
      expect(state.metricImages).toMatchObject([initialImage, newImage]);
    });
  });

  describe('RECEIVE_METRIC_UPLOAD_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_METRIC_UPLOAD_ERROR](state);
    });

    it('should unset the loading state', () => {
      expect(state.isUploadingImage).toBe(false);
    });
  });

  describe('RECEIVE_METRIC_UPDATE_SUCCESS', () => {
    const initialImage = testImages[0];
    const newImage = testImages[0];
    newImage.url = 'https://www.gitlab.com';

    beforeEach(() => {
      createState({ metricImages: [initialImage] });
      mutations[types.RECEIVE_METRIC_UPDATE_SUCCESS](state, newImage);
    });

    it('should unset the loading state', () => {
      expect(state.isUploadingImage).toBe(false);
    });

    it('should replace the existing image with the new one', () => {
      expect(state.metricImages).toMatchObject([newImage]);
    });
  });

  describe('RECEIVE_METRIC_DELETE_SUCCESS', () => {
    const deletedImageId = testImages[1].id;
    const expectedResult = [testImages[0], testImages[2]];

    beforeEach(() => {
      createState({ metricImages: [...testImages] });
      mutations[types.RECEIVE_METRIC_DELETE_SUCCESS](state, deletedImageId);
    });

    it('should remove the correct metric image', () => {
      expect(state.metricImages).toEqual(expectedResult);
    });
  });

  describe('SET_INITIAL_DATA', () => {
    beforeEach(() => {
      mutations[types.SET_INITIAL_DATA](state, initialData);
    });

    it('should unset the loading state', () => {
      expect(state.modelIid).toBe(initialData.modelIid);
      expect(state.projectId).toBe(initialData.projectId);
    });
  });
});
