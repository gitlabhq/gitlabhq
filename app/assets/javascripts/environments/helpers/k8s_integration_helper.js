import csrf from '~/lib/utils/csrf';
import { CLUSTER_AGENT_ERROR_MESSAGES } from '../constants';

export function humanizeClusterErrors(reason) {
  const errorReason = String(reason).toLowerCase();
  const errorMessage = CLUSTER_AGENT_ERROR_MESSAGES[errorReason];
  return errorMessage || CLUSTER_AGENT_ERROR_MESSAGES.other;
}

export function createK8sAccessConfiguration({ kasTunnelUrl, gitlabAgentId }) {
  return {
    basePath: kasTunnelUrl,
    headers: {
      'GitLab-Agent-Id': gitlabAgentId,
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...csrf.headers,
    },
    credentials: 'include',
  };
}
