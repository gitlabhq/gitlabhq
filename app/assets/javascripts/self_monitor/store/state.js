import { parseBoolean } from '~/lib/utils/common_utils';

export default (initialState = {}) => ({
  projectEnabled: parseBoolean(initialState.projectEnabled) || false,
  projectCreated: parseBoolean(initialState.selfMonitorProjectCreated) || false,
  createProjectEndpoint: initialState.createSelfMonitoringProjectPath || '',
  deleteProjectEndpoint: initialState.deleteSelfMonitoringProjectPath || '',
  createProjectStatusEndpoint: initialState.statusCreateSelfMonitoringProjectPath || '',
  deleteProjectStatusEndpoint: initialState.statusDeleteSelfMonitoringProjectPath || '',
  selfMonitorProjectPath: initialState.selfMonitoringProjectFullPath || '',
  showAlert: false,
  projectPath: '',
  loading: false,
  alertContent: {},
});
