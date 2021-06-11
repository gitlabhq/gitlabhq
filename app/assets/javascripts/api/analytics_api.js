import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const PROJECT_VSA_PATH_BASE = '/:project_path/-/analytics/value_stream_analytics/value_streams';
const PROJECT_VSA_STAGES_PATH = `${PROJECT_VSA_PATH_BASE}/:value_stream_id/stages`;

const buildProjectValueStreamPath = (projectPath, valueStreamId = null) => {
  if (valueStreamId) {
    return buildApiUrl(PROJECT_VSA_STAGES_PATH)
      .replace(':project_path', projectPath)
      .replace(':value_stream_id', valueStreamId);
  }
  return buildApiUrl(PROJECT_VSA_PATH_BASE).replace(':project_path', projectPath);
};

export const getProjectValueStreams = (projectPath) => {
  const url = buildProjectValueStreamPath(projectPath);
  return axios.get(url);
};

export const getProjectValueStreamStages = (projectPath, valueStreamId) => {
  const url = buildProjectValueStreamPath(projectPath, valueStreamId);
  return axios.get(url);
};

// NOTE: legacy VSA request use a different path
// the `requestPath` provides a full url for the request
export const getProjectValueStreamStageData = ({ requestPath, stageId, params }) =>
  axios.get(`${requestPath}/events/${stageId}`, { params });

export const getProjectValueStreamMetrics = (requestPath, params) =>
  axios.get(requestPath, { params });
