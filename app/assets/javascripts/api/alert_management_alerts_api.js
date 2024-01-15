import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';
import { contentTypeMultipartFormData } from '~/lib/utils/headers';

const ALERT_METRIC_IMAGES_PATH =
  '/api/:version/projects/:id/alert_management_alerts/:alert_iid/metric_images';
const ALERT_SINGLE_METRIC_IMAGE_PATH =
  '/api/:version/projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id';

export function fetchAlertMetricImages({ alertIid, id }) {
  const metricImagesUrl = buildApiUrl(ALERT_METRIC_IMAGES_PATH)
    .replace(':id', encodeURIComponent(id))
    .replace(':alert_iid', encodeURIComponent(alertIid));

  return axios.get(metricImagesUrl);
}

export function uploadAlertMetricImage({ alertIid, id, file, url = null, urlText = null }) {
  const options = { headers: { ...contentTypeMultipartFormData } };
  const metricImagesUrl = buildApiUrl(ALERT_METRIC_IMAGES_PATH)
    .replace(':id', encodeURIComponent(id))
    .replace(':alert_iid', encodeURIComponent(alertIid));

  // Construct multipart form data
  const formData = new FormData();
  formData.append('file', file);
  if (url) {
    formData.append('url', url);
  }
  if (urlText) {
    formData.append('url_text', urlText);
  }

  return axios.post(metricImagesUrl, formData, options);
}

export function updateAlertMetricImage({ alertIid, id, imageId, url = null, urlText = null }) {
  const metricImagesUrl = buildApiUrl(ALERT_SINGLE_METRIC_IMAGE_PATH)
    .replace(':id', encodeURIComponent(id))
    .replace(':alert_iid', encodeURIComponent(alertIid))
    .replace(':image_id', encodeURIComponent(imageId));

  // Construct multipart form data
  const formData = new FormData();
  if (url != null) {
    formData.append('url', url);
  }
  if (urlText != null) {
    formData.append('url_text', urlText);
  }

  return axios.put(metricImagesUrl, formData);
}

export function deleteAlertMetricImage({ alertIid, id, imageId }) {
  const individualMetricImageUrl = buildApiUrl(ALERT_SINGLE_METRIC_IMAGE_PATH)
    .replace(':id', encodeURIComponent(id))
    .replace(':alert_iid', encodeURIComponent(alertIid))
    .replace(':image_id', encodeURIComponent(imageId));

  return axios.delete(individualMetricImageUrl);
}
