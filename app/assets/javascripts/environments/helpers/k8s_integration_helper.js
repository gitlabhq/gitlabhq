import { CLUSTER_AGENT_ERROR_MESSAGES } from '../constants';

export function humanizeClusterErrors(reason) {
  const errorReason = String(reason).toLowerCase();
  const errorMessage = CLUSTER_AGENT_ERROR_MESSAGES[errorReason];
  return errorMessage || CLUSTER_AGENT_ERROR_MESSAGES.other;
}
