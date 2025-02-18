import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { buildApiUrl } from './api_utils';

const PROJECT_VSA_METRICS_BASE = '/:namespace_path/-/analytics/value_stream_analytics';
const PROJECT_VSA_PATH_BASE = '/:namespace_path/-/analytics/value_stream_analytics/value_streams';
const PROJECT_VSA_STAGES_PATH = `${PROJECT_VSA_PATH_BASE}/:value_stream_id/stages`;
const PROJECT_VSA_STAGE_DATA_PATH = `${PROJECT_VSA_STAGES_PATH}/:stage_id`;

export const LEAD_TIME_METRIC_TYPE = 'lead_time';
export const CYCLE_TIME_METRIC_TYPE = 'cycle_time';
export const ISSUES_METRIC_TYPE = 'issues';
export const DEPLOYS_METRIC_TYPE = 'deploys';

const buildProjectMetricsPath = (namespacePath) =>
  buildApiUrl(PROJECT_VSA_METRICS_BASE).replace(':namespace_path', namespacePath);

const buildProjectValueStreamPath = (namespacePath, valueStreamId = null) => {
  if (valueStreamId) {
    return buildApiUrl(PROJECT_VSA_STAGES_PATH)
      .replace(':namespace_path', namespacePath)
      .replace(':value_stream_id', valueStreamId);
  }
  return buildApiUrl(PROJECT_VSA_PATH_BASE).replace(':namespace_path', namespacePath);
};

const buildValueStreamStageDataPath = ({ namespacePath, valueStreamId = null, stageId = null }) =>
  buildApiUrl(PROJECT_VSA_STAGE_DATA_PATH)
    .replace(':namespace_path', namespacePath)
    .replace(':value_stream_id', valueStreamId)
    .replace(':stage_id', stageId);

export const getProjectValueStreams = (namespacePath) => {
  const url = buildProjectValueStreamPath(namespacePath);
  return axios.get(url);
};

export const getProjectValueStreamStages = (namespacePath, valueStreamId) => {
  const url = buildProjectValueStreamPath(namespacePath, valueStreamId);
  return axios.get(url);
};

// NOTE: legacy VSA request use a different path
// the `namespacePath` provides a full url for the request
export const getProjectValueStreamStageData = ({ namespacePath, stageId, params }) =>
  axios.get(joinPaths(namespacePath, 'events', stageId), { params });

/**
 * Dedicated project VSA paths
 */

export const getValueStreamStageMedian = (
  { namespacePath, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildValueStreamStageDataPath({ namespacePath, valueStreamId, stageId });
  return axios.get(joinPaths(stageBase, 'median'), { params });
};

export const getValueStreamStageRecords = (
  { namespacePath, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildValueStreamStageDataPath({ namespacePath, valueStreamId, stageId });
  return axios.get(joinPaths(stageBase, 'records'), { params });
};

export const getValueStreamStageCounts = (
  { namespacePath, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildValueStreamStageDataPath({ namespacePath, valueStreamId, stageId });
  return axios.get(joinPaths(stageBase, 'count'), { params });
};

export const getValueStreamSummaryMetrics = (namespacePath, params = {}) => {
  const metricBase = buildProjectMetricsPath(namespacePath);
  return axios.get(joinPaths(metricBase, 'summary'), { params });
};
