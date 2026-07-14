import { createTestingPinia } from '@pinia/testing';
import { useMetricImages } from '~/vue_shared/components/metric_images/store';
import { createAlert } from '~/alert';
import { fileList, initialData } from '../mock_data';

jest.mock('~/alert');

const service = {
  getMetricImages: jest.fn(),
  uploadMetricImage: jest.fn(),
  updateMetricImage: jest.fn(),
  deleteMetricImage: jest.fn(),
};

const defaultState = {
  modelIid: 1,
  projectId: '2',
};

describe('Metric images store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useMetricImages();
    store.setInitialData({ ...defaultState, service });
  });

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('setInitialData', () => {
    it('sets modelIid and projectId', () => {
      store.setInitialData(initialData);

      expect(store.modelIid).toBe(initialData.modelIid);
      expect(store.projectId).toBe(initialData.projectId);
    });
  });

  describe('fetchImages', () => {
    it('sets loading state', () => {
      service.getMetricImages.mockReturnValue(new Promise(() => {}));

      store.fetchImages();

      expect(store.isLoadingMetricImages).toBe(true);
    });

    it('sets metric images on success', async () => {
      service.getMetricImages.mockResolvedValue(fileList);

      await store.fetchImages();

      expect(store.isLoadingMetricImages).toBe(false);
      expect(store.metricImages).toEqual(fileList);
    });

    it('sets empty array when response is falsy', async () => {
      store.metricImages = [...fileList];
      service.getMetricImages.mockResolvedValue(null);

      await store.fetchImages();

      expect(store.metricImages).toEqual([]);
    });

    it('leaves metricImages unchanged and unsets loading state on error', async () => {
      service.getMetricImages.mockRejectedValue();

      await store.fetchImages();

      expect(store.metricImages).toEqual([]);
      expect(store.isLoadingMetricImages).toBe(false);
    });

    it('shows alert on error', async () => {
      service.getMetricImages.mockRejectedValue();

      await store.fetchImages();

      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('uploadImage', () => {
    const payload = {
      files: { item: () => fileList[0] },
      url: 'test_url',
    };

    it('sets uploading state', () => {
      service.uploadMetricImage.mockReturnValue(new Promise(() => {}));

      store.uploadImage(payload);

      expect(store.isUploadingImage).toBe(true);
    });

    it('adds image to list on success', async () => {
      service.uploadMetricImage.mockResolvedValue(fileList[0]);

      await store.uploadImage(payload);

      expect(store.isUploadingImage).toBe(false);
      expect(store.metricImages).toEqual([fileList[0]]);
    });

    it('leaves metricImages unchanged and unsets uploading state on error', async () => {
      store.metricImages = [...fileList];
      service.uploadMetricImage.mockRejectedValue();

      await store.uploadImage(payload);

      expect(store.metricImages).toEqual([...fileList]);
      expect(store.isUploadingImage).toBe(false);
    });

    it('shows alert on error', async () => {
      service.uploadMetricImage.mockRejectedValue();

      await store.uploadImage(payload);

      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('updateImage', () => {
    const payload = { imageId: 5, url: 'test_url', urlText: 'url text' };

    it('sets uploading state', () => {
      service.updateMetricImage.mockReturnValue(new Promise(() => {}));

      store.updateImage(payload);

      expect(store.isUploadingImage).toBe(true);
    });

    it('replaces the image on success', async () => {
      store.metricImages = [{ id: 5, url: null }];
      const updatedImage = { id: 5, url: 'test_url' };
      service.updateMetricImage.mockResolvedValue(updatedImage);

      await store.updateImage(payload);

      expect(store.isUploadingImage).toBe(false);
      expect(store.metricImages).toEqual([updatedImage]);
    });

    it('leaves metricImages unchanged when image not found', async () => {
      const existingImages = [{ id: 99, url: null }];
      store.metricImages = existingImages;
      service.updateMetricImage.mockResolvedValue({ id: 5, url: 'test_url' });

      await store.updateImage(payload);

      expect(store.metricImages).toEqual(existingImages);
      expect(store.isUploadingImage).toBe(false);
    });

    it('leaves metricImages unchanged and unsets uploading state on error', async () => {
      const existingImage = { id: 5, url: null };
      store.metricImages = [existingImage];
      service.updateMetricImage.mockRejectedValue();

      await store.updateImage(payload);

      expect(store.metricImages).toEqual([existingImage]);
      expect(store.isUploadingImage).toBe(false);
    });

    it('shows alert on error', async () => {
      service.updateMetricImage.mockRejectedValue();

      await store.updateImage(payload);

      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('deleteImage', () => {
    it('removes the image on success', async () => {
      store.metricImages = [...fileList];
      service.deleteMetricImage.mockResolvedValue();

      await store.deleteImage(fileList[0].id);

      expect(store.metricImages).toEqual([]);
    });

    it('leaves metricImages unchanged when image not found', async () => {
      store.metricImages = [...fileList];
      service.deleteMetricImage.mockResolvedValue();

      await store.deleteImage(9999);

      expect(store.metricImages).toEqual([...fileList]);
    });

    it('leaves metricImages unchanged and shows alert on error', async () => {
      store.metricImages = [...fileList];
      service.deleteMetricImage.mockRejectedValue();

      await store.deleteImage(fileList[0].id);

      expect(store.metricImages).toEqual([...fileList]);
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
