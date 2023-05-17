import { differenceInSeconds } from '~/lib/utils/datetime_utility';

export function generateServicePortsString(ports) {
  if (!ports?.length) return '';

  return ports
    .map((port) => {
      const nodePort = port.nodePort ? `:${port.nodePort}` : '';
      return `${port.port}${nodePort}/${port.protocol}`;
    })
    .join(', ');
}

export function getServiceAge(creationTimestamp) {
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

export function getDeploymentsStatuses(items) {
  const failed = [];
  const ready = [];

  items.forEach((item) => {
    const [available, progressing] = item.status?.conditions ?? [];
    // eslint-disable-next-line @gitlab/require-i18n-strings
    if (available.status === 'True') {
      ready.push(item);
      // eslint-disable-next-line @gitlab/require-i18n-strings
    } else if (available.status !== 'True' && progressing.status !== 'True') {
      failed.push(item);
    }
  });

  return {
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
