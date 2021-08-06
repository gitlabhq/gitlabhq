import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { buildApiUrl } from './api_utils';

const PROJECT_VSA_PATH_BASE = '/:request_path/-/analytics/value_stream_analytics/value_streams';
const PROJECT_VSA_STAGES_PATH = `${PROJECT_VSA_PATH_BASE}/:value_stream_id/stages`;
const PROJECT_VSA_STAGE_DATA_PATH = `${PROJECT_VSA_STAGES_PATH}/:stage_id`;

const buildProjectValueStreamPath = (requestPath, valueStreamId = null) => {
  if (valueStreamId) {
    return buildApiUrl(PROJECT_VSA_STAGES_PATH)
      .replace(':request_path', requestPath)
      .replace(':value_stream_id', valueStreamId);
  }
  return buildApiUrl(PROJECT_VSA_PATH_BASE).replace(':request_path', requestPath);
};

const buildValueStreamStageDataPath = ({ requestPath, valueStreamId = null, stageId = null }) =>
  buildApiUrl(PROJECT_VSA_STAGE_DATA_PATH)
    .replace(':request_path', requestPath)
    .replace(':value_stream_id', valueStreamId)
    .replace(':stage_id', stageId);

export const getProjectValueStreams = (requestPath) => {
  const url = buildProjectValueStreamPath(requestPath);
  return axios.get(url);
};

export const getProjectValueStreamStages = (requestPath, valueStreamId) => {
  const url = buildProjectValueStreamPath(requestPath, valueStreamId);
  return axios.get(url);
};

// NOTE: legacy VSA request use a different path
// the `requestPath` provides a full url for the request
export const getProjectValueStreamStageData = ({ requestPath, stageId, params }) =>
  axios.get(joinPaths(requestPath, 'events', stageId), { params });

export const getProjectValueStreamMetrics = (requestPath, params) =>
  axios.get(requestPath, { params });

/**
 * Shared group VSA paths
 * We share some endpoints across and group and project level VSA
 * When used for project level VSA, requests should include the `project_id` in the params object
 */

export const getValueStreamStageMedian = ({ requestPath, valueStreamId, stageId }, params = {}) => {
  const stageBase = buildValueStreamStageDataPath({ requestPath, valueStreamId, stageId });
  return axios.get(joinPaths(stageBase, 'median'), { params });
};

export const getValueStreamStageRecords = (
  { requestPath, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildValueStreamStageDataPath({ requestPath, valueStreamId, stageId });
  return axios.get(joinPaths(stageBase, 'records'), { params });
};

export const getValueStreamStageCounts = ({ requestPath, valueStreamId, stageId }, params = {}) => {
  const stageBase = buildValueStreamStageDataPath({ requestPath, valueStreamId, stageId });
  return axios.get(joinPaths(stageBase, 'count'), { params });
};
