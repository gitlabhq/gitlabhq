import { fileList, fileListRaw } from 'jest/vue_shared/components/metric_images/mock_data';
import {
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
  deleteMetricImage,
} from '~/vue_shared/alert_details/service';
import * as alertManagementAlertsApi from '~/api/alert_management_alerts_api';

jest.mock('~/api/alert_management_alerts_api');

describe('Alert details service', () => {
  it('fetches metric images', async () => {
    alertManagementAlertsApi.fetchAlertMetricImages.mockResolvedValue({ data: fileListRaw });
    const result = await getMetricImages();

    expect(alertManagementAlertsApi.fetchAlertMetricImages).toHaveBeenCalled();
    expect(result).toEqual(fileList);
  });

  it('uploads a metric image', async () => {
    alertManagementAlertsApi.uploadAlertMetricImage.mockResolvedValue({ data: fileListRaw[0] });
    const result = await uploadMetricImage();

    expect(alertManagementAlertsApi.uploadAlertMetricImage).toHaveBeenCalled();
    expect(result).toEqual(fileList[0]);
  });

  it('updates a metric image', async () => {
    alertManagementAlertsApi.updateAlertMetricImage.mockResolvedValue({ data: fileListRaw[0] });
    const result = await updateMetricImage();

    expect(alertManagementAlertsApi.updateAlertMetricImage).toHaveBeenCalled();
    expect(result).toEqual(fileList[0]);
  });

  it('deletes a metric image', async () => {
    alertManagementAlertsApi.deleteAlertMetricImage.mockResolvedValue({ data: '' });
    const result = await deleteMetricImage();

    expect(alertManagementAlertsApi.deleteAlertMetricImage).toHaveBeenCalled();
    expect(result).toEqual({});
  });
});
