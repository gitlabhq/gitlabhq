import MockAdapter from 'axios-mock-adapter';
import * as alertManagementAlertsApi from '~/api/alert_management_alerts_api';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';

describe('~/api/alert_management_alerts_api.js', () => {
  let mock;

  const projectId = 1;
  const alertIid = 2;

  const imageData = { filePath: 'test', filename: 'hello', id: 5, url: null };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchAlertMetricImages', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
    });

    it('retrieves metric images from the correct URL and returns them in the response data', () => {
      const expectedUrl = `/api/v4/projects/${projectId}/alert_management_alerts/${alertIid}/metric_images`;
      const expectedData = [imageData];
      const options = { alertIid, id: projectId };

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, { data: expectedData });

      return alertManagementAlertsApi.fetchAlertMetricImages(options).then(({ data }) => {
        expect(axios.get).toHaveBeenCalledWith(expectedUrl);
        expect(data.data).toEqual(expectedData);
      });
    });
  });

  describe('uploadAlertMetricImage', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'post');
    });

    it('uploads a metric image to the correct URL and returns it in the response data', () => {
      const expectedUrl = `/api/v4/projects/${projectId}/alert_management_alerts/${alertIid}/metric_images`;
      const expectedData = [imageData];

      const file = new File(['zip contents'], 'hello');
      const url = 'https://www.example.com';
      const urlText = 'Example website';

      const expectedFormData = new FormData();
      expectedFormData.append('file', file);
      expectedFormData.append('url', url);
      expectedFormData.append('url_text', urlText);

      mock.onPost(expectedUrl).reply(HTTP_STATUS_CREATED, { data: expectedData });

      return alertManagementAlertsApi
        .uploadAlertMetricImage({
          alertIid,
          id: projectId,
          file,
          url,
          urlText,
        })
        .then(({ data }) => {
          expect(data).toEqual({ data: expectedData });
          expect(axios.post).toHaveBeenCalledWith(expectedUrl, expectedFormData, {
            headers: { 'Content-Type': 'multipart/form-data' },
          });
        });
    });
  });

  describe('updateAlertMetricImage', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'put');
    });

    it('updates a metric image to the correct URL and returns it in the response data', () => {
      const imageIid = 3;
      const expectedUrl = `/api/v4/projects/${projectId}/alert_management_alerts/${alertIid}/metric_images/${imageIid}`;
      const expectedData = [imageData];

      const url = 'https://www.example.com';
      const urlText = 'Example website';

      const expectedFormData = new FormData();
      expectedFormData.append('url', url);
      expectedFormData.append('url_text', urlText);

      mock.onPut(expectedUrl).reply(HTTP_STATUS_OK, { data: expectedData });

      return alertManagementAlertsApi
        .updateAlertMetricImage({
          alertIid,
          id: projectId,
          imageId: imageIid,
          url,
          urlText,
        })
        .then(({ data }) => {
          expect(data).toEqual({ data: expectedData });
          expect(axios.put).toHaveBeenCalledWith(expectedUrl, expectedFormData);
        });
    });
  });

  describe('deleteAlertMetricImage', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'delete');
    });

    it('deletes a metric image to the correct URL and returns it in the response data', () => {
      const imageIid = 3;
      const expectedUrl = `/api/v4/projects/${projectId}/alert_management_alerts/${alertIid}/metric_images/${imageIid}`;
      const expectedData = [imageData];

      mock.onDelete(expectedUrl).reply(HTTP_STATUS_NO_CONTENT, { data: expectedData });

      return alertManagementAlertsApi
        .deleteAlertMetricImage({
          alertIid,
          id: projectId,
          imageId: imageIid,
        })
        .then(({ data }) => {
          expect(data).toEqual({ data: expectedData });
          expect(axios.delete).toHaveBeenCalledWith(expectedUrl);
        });
    });
  });
});
