import {
  fetchAlertMetricImages,
  uploadAlertMetricImage,
  updateAlertMetricImage,
  deleteAlertMetricImage,
} from '~/rest_api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

function replaceModelIId(payload = {}) {
  delete Object.assign(payload, { alertIid: payload.modelIid }).modelIid;
  return payload;
}

export const getMetricImages = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await fetchAlertMetricImages(apiPayload);
  return convertObjectPropsToCamelCase(response.data, { deep: true });
};

export const uploadMetricImage = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await uploadAlertMetricImage(apiPayload);
  return convertObjectPropsToCamelCase(response.data);
};

export const updateMetricImage = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await updateAlertMetricImage(apiPayload);
  return convertObjectPropsToCamelCase(response.data);
};

export const deleteMetricImage = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await deleteAlertMetricImage(apiPayload);
  return convertObjectPropsToCamelCase(response.data);
};

export default {
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
  deleteMetricImage,
};
