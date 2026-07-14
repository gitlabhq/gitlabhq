import { defineStore } from 'pinia';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

export const useMetricImages = defineStore('metricImages', {
  state() {
    return {
      modelIid: undefined,
      projectId: undefined,
      metricImages: [],
      isLoadingMetricImages: false,
      isUploadingImage: false,
      service: null,
    };
  },
  actions: {
    setInitialData({ modelIid, projectId, service }) {
      this.modelIid = modelIid;
      this.projectId = projectId;
      this.service = service;
    },
    async fetchImages() {
      this.isLoadingMetricImages = true;

      try {
        const response = await this.service.getMetricImages({
          id: this.projectId,
          modelIid: this.modelIid,
        });
        this.metricImages = response || [];
      } catch {
        createAlert({ message: s__('MetricImages|There was an issue loading metric images.') });
      } finally {
        this.isLoadingMetricImages = false;
      }
    },
    async uploadImage({ files, url, urlText }) {
      this.isUploadingImage = true;

      try {
        const response = await this.service.uploadMetricImage({
          file: files.item(0),
          id: this.projectId,
          modelIid: this.modelIid,
          url,
          urlText,
        });
        this.metricImages.push(response);
      } catch {
        createAlert({ message: s__('MetricImages|There was an issue uploading your image.') });
      } finally {
        this.isUploadingImage = false;
      }
    },
    async updateImage({ imageId, url, urlText }) {
      this.isUploadingImage = true;

      try {
        const response = await this.service.updateMetricImage({
          modelIid: this.modelIid,
          id: this.projectId,
          imageId,
          url,
          urlText,
        });
        const metricIndex = this.metricImages.findIndex((img) => img.id === response.id);
        if (metricIndex >= 0) {
          this.metricImages.splice(metricIndex, 1, response);
        }
      } catch {
        createAlert({ message: s__('MetricImages|There was an issue updating your image.') });
      } finally {
        this.isUploadingImage = false;
      }
    },
    async deleteImage(imageId) {
      try {
        await this.service.deleteMetricImage({
          imageId,
          id: this.projectId,
          modelIid: this.modelIid,
        });
        const metricIndex = this.metricImages.findIndex((image) => image.id === imageId);
        if (metricIndex >= 0) {
          this.metricImages.splice(metricIndex, 1);
        }
      } catch {
        createAlert({ message: s__('MetricImages|There was an issue deleting the image.') });
      }
    },
  },
});
