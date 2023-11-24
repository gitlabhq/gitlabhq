import { CLUSTER_AGENT_ERROR_MESSAGES, STATUS_TRUE, STATUS_FALSE } from '../constants';

export function generateServicePortsString(ports) {
  if (!ports?.length) return '';

  return ports
    .map((port) => {
      const nodePort = port.nodePort ? `:${port.nodePort}` : '';
      return `${port.port}${nodePort}/${port.protocol}`;
    })
    .join(', ');
}

export function getDeploymentsStatuses(items) {
  const failed = [];
  const ready = [];
  const pending = [];

  items.forEach((item) => {
    const [available, progressing] = item.status?.conditions ?? [];
    if (available?.status === STATUS_TRUE) {
      ready.push(item);
    } else if (available?.status === STATUS_FALSE && progressing?.status !== STATUS_TRUE) {
      failed.push(item);
    } else {
      pending.push(item);
    }
  });

  return {
    ...(pending.length && { pending }),
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

export function getDaemonSetStatuses(items) {
  const failed = items.filter((item) => {
    return (
      item.status?.numberMisscheduled > 0 ||
      item.status?.numberReady !== item.status?.desiredNumberScheduled
    );
  });
  const ready = items.filter((item) => {
    return (
      item.status?.numberReady === item.status?.desiredNumberScheduled &&
      !item.status?.numberMisscheduled
    );
  });

  return {
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

export function getStatefulSetStatuses(items) {
  const failed = items.filter((item) => {
    return item.status?.readyReplicas < item.spec?.replicas;
  });
  const ready = items.filter((item) => {
    return item.status?.readyReplicas === item.spec?.replicas;
  });

  return {
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

export function getReplicaSetStatuses(items) {
  const failed = items.filter((item) => {
    return item.status?.readyReplicas < item.spec?.replicas;
  });
  const ready = items.filter((item) => {
    return item.status?.readyReplicas === item.spec?.replicas;
  });

  return {
    ...(failed.length && { failed }),
    ...(ready.length && { ready }),
  };
}

export function getJobsStatuses(items) {
  const failed = items.filter((item) => {
    return item.status.failed > 0 || item.status?.succeeded !== item.spec?.completions;
  });
  const completed = items.filter((item) => {
    return item.status?.succeeded === item.spec?.completions;
  });

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
    if (item.status?.active > 0 && !item.status?.lastScheduleTime) {
      failed.push(item);
    } else if (item.spec?.suspend) {
      suspended.push(item);
    } else if (item.status?.lastScheduleTime) {
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
