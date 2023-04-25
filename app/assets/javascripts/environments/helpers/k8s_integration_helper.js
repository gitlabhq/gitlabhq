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
