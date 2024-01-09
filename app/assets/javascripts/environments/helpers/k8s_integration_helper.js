import {
  calculateDeploymentStatus,
  calculateStatefulSetStatus,
  calculateDaemonSetStatus,
  calculateJobStatus,
  calculateCronJobStatus,
} from '~/kubernetes_dashboard/helpers/k8s_integration_helper';
import {
  STATUS_READY,
  STATUS_FAILED,
  STATUS_COMPLETED,
  STATUS_SUSPENDED,
} from '~/kubernetes_dashboard/constants';
import { CLUSTER_AGENT_ERROR_MESSAGES } from '../constants';

export function getDeploymentsStatuses(items) {
  const failed = [];
  const ready = [];
  const pending = [];

  items.forEach((item) => {
    const status = calculateDeploymentStatus(item);

    switch (status) {
      case STATUS_READY:
        ready.push(item);
        break;
      case STATUS_FAILED:
        failed.push(item);
        break;
      default:
        pending.push(item);
        break;
    }
  });

  return {
    ...(pending.length && { pending }),
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

const isCompleted = (status) => status === STATUS_COMPLETED;
const isReady = (status) => status === STATUS_READY;
const isFailed = (status) => status === STATUS_FAILED;
const isSuspended = (status) => status === STATUS_SUSPENDED;

export function getDaemonSetStatuses(items) {
  const failed = items.filter((item) => isFailed(calculateDaemonSetStatus(item)));
  const ready = items.filter((item) => isReady(calculateDaemonSetStatus(item)));

  return {
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

export function getStatefulSetStatuses(items) {
  const failed = items.filter((item) => isFailed(calculateStatefulSetStatus(item)));
  const ready = items.filter((item) => isReady(calculateStatefulSetStatus(item)));

  return {
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

export function getReplicaSetStatuses(items) {
  const failed = items.filter((item) => isFailed(calculateStatefulSetStatus(item)));
  const ready = items.filter((item) => isReady(calculateStatefulSetStatus(item)));

  return {
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

export function getJobsStatuses(items) {
  const failed = items.filter((item) => isFailed(calculateJobStatus(item)));
  const completed = items.filter((item) => isCompleted(calculateJobStatus(item)));

  return {
    ...(failed.length && { failed }),
    ...(completed.length && { completed }),
  };
}

export function getCronJobsStatuses(items) {
  const failed = [];
  const ready = [];
  const suspended = [];

  items.forEach((item) => {
    if (isFailed(calculateCronJobStatus(item))) {
      failed.push(item);
    } else if (isSuspended(calculateCronJobStatus(item))) {
      suspended.push(item);
    } else if (isReady(calculateCronJobStatus(item))) {
      ready.push(item);
    }
  });

  return {
    ...(failed.length && { failed }),
    ...(suspended.length && { suspended }),
    ...(ready.length && { ready }),
  };
}

export function humanizeClusterErrors(reason) {
  const errorReason = String(reason).toLowerCase();
  const errorMessage = CLUSTER_AGENT_ERROR_MESSAGES[errorReason];
  return errorMessage || CLUSTER_AGENT_ERROR_MESSAGES.other;
}
