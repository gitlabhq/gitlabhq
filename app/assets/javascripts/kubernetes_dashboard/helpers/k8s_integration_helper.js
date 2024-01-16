import { differenceInSeconds } from '~/lib/utils/datetime_utility';
import {
  STATUS_TRUE,
  STATUS_FALSE,
  STATUS_PENDING,
  STATUS_READY,
  STATUS_FAILED,
  STATUS_COMPLETED,
  STATUS_SUSPENDED,
} from '../constants';

export function getAge(creationTimestamp) {
  if (!creationTimestamp) return '';

  const timeDifference = differenceInSeconds(new Date(creationTimestamp), new Date());

  const seconds = Math.floor(timeDifference);
  const minutes = Math.floor(seconds / 60) % 60;
  const hours = Math.floor(seconds / 60 / 60) % 24;
  const days = Math.floor(seconds / 60 / 60 / 24);

  let ageString;
  if (days > 0) {
    ageString = `${days}d`;
  } else if (hours > 0) {
    ageString = `${hours}h`;
  } else if (minutes > 0) {
    ageString = `${minutes}m`;
  } else {
    ageString = `${seconds}s`;
  }

  return ageString;
}

export function calculateDeploymentStatus(item) {
  const [available, progressing] = item.status?.conditions ?? [];
  if (available?.status === STATUS_TRUE) {
    return STATUS_READY;
  }
  if (available?.status === STATUS_FALSE && progressing?.status !== STATUS_TRUE) {
    return STATUS_FAILED;
  }
  return STATUS_PENDING;
}

export function calculateStatefulSetStatus(item) {
  if (item.status?.readyReplicas === item.spec?.replicas) {
    return STATUS_READY;
  }
  return STATUS_FAILED;
}

export function calculateDaemonSetStatus(item) {
  if (
    item.status?.numberReady === item.status?.desiredNumberScheduled &&
    !item.status?.numberMisscheduled
  ) {
    return STATUS_READY;
  }
  return STATUS_FAILED;
}

export function calculateJobStatus(item) {
  if (item.status.failed > 0 || item.status?.succeeded !== item.spec?.completions) {
    return STATUS_FAILED;
  }
  return STATUS_COMPLETED;
}

export function calculateCronJobStatus(item) {
  if (item.status?.active > 0 && !item.status?.lastScheduleTime) {
    return STATUS_FAILED;
  }
  if (item.spec?.suspend) {
    return STATUS_SUSPENDED;
  }
  return STATUS_READY;
}

export function generateServicePortsString(ports) {
  if (!ports?.length) return '';

  return ports
    .map((port) => {
      const nodePort = port.nodePort ? `:${port.nodePort}` : '';
      return `${port.port}${nodePort}/${port.protocol}`;
    })
    .join(', ');
}
