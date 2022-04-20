import { parseBoolean } from '~/lib/utils/common_utils';

export default class ClusterStore {
  constructor() {
    this.state = {
      helpPath: null,
      environmentsHelpPath: null,
      clustersHelpPath: null,
      deployBoardsHelpPath: null,
      status: null,
      providerType: null,
      rbac: false,
      statusReason: null,
      environments: [],
      fetchingEnvironments: false,
    };
  }

  setHelpPaths(helpPaths) {
    Object.assign(this.state, {
      ...helpPaths,
    });
  }

  updateStatus(status) {
    this.state.status = status;
  }

  updateProviderType(providerType) {
    this.state.providerType = providerType;
  }

  updateRbac(rbac) {
    this.state.rbac = parseBoolean(rbac);
  }

  updateStatusReason(reason) {
    this.state.statusReason = reason;
  }

  updateStateFromServer(serverState = {}) {
    this.state.status = serverState.status;
    this.state.statusReason = serverState.status_reason;
  }

  toggleFetchEnvironments(isFetching) {
    this.state.fetchingEnvironments = isFetching;
  }

  updateEnvironments(environments = []) {
    this.state.environments = environments.map((environment) => ({
      name: environment.name,
      project: environment.project,
      environmentPath: environment.environment_path,
      logsPath: environment.logs_path,
      lastDeployment: environment.last_deployment,
      rolloutStatus: {
        status: environment.rollout_status ? environment.rollout_status.status : null,
        instances: environment.rollout_status ? environment.rollout_status.instances : [],
      },
      updatedAt: environment.updated_at,
    }));
  }
}
