import { parseBoolean } from '~/lib/utils/common_utils';

export default (initialState = {}) => ({
  projectEnabled: parseBoolean(initialState.selfMonitoringProjectExists) || false,
  projectCreated: parseBoolean(initialState.selfMonitoringProjectExists) || false,
  createProjectEndpoint: initialState.createSelfMonitoringProjectPath || '',
  deleteProjectEndpoint: initialState.deleteSelfMonitoringProjectPath || '',
  createProjectStatusEndpoint: initialState.statusCreateSelfMonitoringProjectPath || '',
  deleteProjectStatusEndpoint: initialState.statusDeleteSelfMonitoringProjectPath || '',
  selfMonitorProjectPath: initialState.selfMonitoringProjectFullPath || '',
  showAlert: false,
  projectPath: initialState.selfMonitoringProjectFullPath || '',
  loading: false,
  alertContent: {},
});
