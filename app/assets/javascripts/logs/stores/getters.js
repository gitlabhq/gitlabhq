import { formatDate } from '../utils';

const mapTrace = ({ timestamp = null, pod = '', message = '' }) =>
  [timestamp ? formatDate(timestamp) : '', pod, message].join(' | ');

export const trace = (state) => state.logs.lines.map(mapTrace).join('\n');

export const showAdvancedFilters = (state) => {
  if (state.environments.current) {
    const environment = state.environments.options.find(
      ({ name }) => name === state.environments.current,
    );

    return Boolean(environment?.enable_advanced_logs_querying);
  }
  const managedApp = state.managedApps.options.find(
    ({ name }) => name === state.managedApps.current,
  );

  return Boolean(managedApp?.enable_advanced_logs_querying);
};
