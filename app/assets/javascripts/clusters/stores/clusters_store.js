import { s__ } from '../../locale';
import { parseBoolean } from '../../lib/utils/common_utils';
import {
  INGRESS,
  JUPYTER,
  KNATIVE,
  CERT_MANAGER,
  RUNNER,
  APPLICATION_INSTALLED_STATUSES,
  APPLICATION_STATUS,
  INSTALL_EVENT,
  UPDATE_EVENT,
  UNINSTALL_EVENT,
} from '../constants';
import transitionApplicationState from '../services/application_state_machine';

const isApplicationInstalled = appStatus => APPLICATION_INSTALLED_STATUSES.includes(appStatus);

const applicationInitialState = {
  status: null,
  statusReason: null,
  requestReason: null,
  installed: false,
  installFailed: false,
  uninstallable: false,
  uninstallFailed: false,
  uninstallSuccessful: false,
};

export default class ClusterStore {
  constructor() {
    this.state = {
      helpPath: null,
      ingressHelpPath: null,
      status: null,
      rbac: false,
      statusReason: null,
      applications: {
        helm: {
          ...applicationInitialState,
          title: s__('ClusterIntegration|Helm Tiller'),
        },
        ingress: {
          ...applicationInitialState,
          title: s__('ClusterIntegration|Ingress'),
          externalIp: null,
          externalHostname: null,
        },
        cert_manager: {
          ...applicationInitialState,
          title: s__('ClusterIntegration|Cert-Manager'),
          email: null,
        },
        runner: {
          ...applicationInitialState,
          title: s__('ClusterIntegration|GitLab Runner'),
          version: null,
          chartRepo: 'https://gitlab.com/charts/gitlab-runner',
          updateAvailable: null,
          updateSuccessful: false,
          updateFailed: false,
        },
        prometheus: {
          ...applicationInitialState,
          title: s__('ClusterIntegration|Prometheus'),
        },
        jupyter: {
          ...applicationInitialState,
          title: s__('ClusterIntegration|JupyterHub'),
          hostname: null,
        },
        knative: {
          ...applicationInitialState,
          title: s__('ClusterIntegration|Knative'),
          hostname: null,
          isEditingHostName: false,
          externalIp: null,
          externalHostname: null,
          updateSuccessful: false,
          updateFailed: false,
        },
      },
    };
  }

  setHelpPaths(helpPath, ingressHelpPath, ingressDnsHelpPath) {
    this.state.helpPath = helpPath;
    this.state.ingressHelpPath = ingressHelpPath;
    this.state.ingressDnsHelpPath = ingressDnsHelpPath;
  }

  setManagePrometheusPath(managePrometheusPath) {
    this.state.managePrometheusPath = managePrometheusPath;
  }

  updateStatus(status) {
    this.state.status = status;
  }

  updateRbac(rbac) {
    this.state.rbac = parseBoolean(rbac);
  }

  updateStatusReason(reason) {
    this.state.statusReason = reason;
  }

  installApplication(appId) {
    this.handleApplicationEvent(appId, INSTALL_EVENT);
  }

  notifyInstallFailure(appId) {
    this.handleApplicationEvent(appId, APPLICATION_STATUS.ERROR);
  }

  updateApplication(appId) {
    this.handleApplicationEvent(appId, UPDATE_EVENT);
  }

  notifyUpdateFailure(appId) {
    this.handleApplicationEvent(appId, APPLICATION_STATUS.UPDATE_ERRORED);
  }

  uninstallApplication(appId) {
    this.handleApplicationEvent(appId, UNINSTALL_EVENT);
  }

  notifyUninstallFailure(appId) {
    this.handleApplicationEvent(appId, APPLICATION_STATUS.UNINSTALL_ERRORED);
  }

  handleApplicationEvent(appId, event) {
    const currentAppState = this.state.applications[appId];

    this.state.applications[appId] = transitionApplicationState(currentAppState, event);
  }

  updateAppProperty(appId, prop, value) {
    this.state.applications[appId][prop] = value;
  }

  updateStateFromServer(serverState = {}) {
    this.state.status = serverState.status;
    this.state.statusReason = serverState.status_reason;

    serverState.applications.forEach(serverAppEntry => {
      const {
        name: appId,
        status,
        status_reason: statusReason,
        version,
        update_available: updateAvailable,
        can_uninstall: uninstallable,
      } = serverAppEntry;
      const currentApplicationState = this.state.applications[appId] || {};
      const nextApplicationState = transitionApplicationState(currentApplicationState, status);

      this.state.applications[appId] = {
        ...currentApplicationState,
        ...nextApplicationState,
        statusReason,
        installed: isApplicationInstalled(nextApplicationState.status),
        uninstallable,
      };

      if (appId === INGRESS) {
        this.state.applications.ingress.externalIp = serverAppEntry.external_ip;
        this.state.applications.ingress.externalHostname = serverAppEntry.external_hostname;
      } else if (appId === CERT_MANAGER) {
        this.state.applications.cert_manager.email =
          this.state.applications.cert_manager.email || serverAppEntry.email;
      } else if (appId === JUPYTER) {
        this.state.applications.jupyter.hostname =
          serverAppEntry.hostname ||
          (this.state.applications.ingress.externalIp
            ? `jupyter.${this.state.applications.ingress.externalIp}.nip.io`
            : '');
      } else if (appId === KNATIVE) {
        if (!this.state.applications.knative.isEditingHostName) {
          this.state.applications.knative.hostname =
            serverAppEntry.hostname || this.state.applications.knative.hostname;
        }
        this.state.applications.knative.externalIp =
          serverAppEntry.external_ip || this.state.applications.knative.externalIp;
        this.state.applications.knative.externalHostname =
          serverAppEntry.external_hostname || this.state.applications.knative.externalHostname;
      } else if (appId === RUNNER) {
        this.state.applications.runner.version = version;
        this.state.applications.runner.updateAvailable = updateAvailable;
      }
    });
  }
}
