import { s__ } from '../../locale';
import { parseBoolean } from '../../lib/utils/common_utils';
import {
  INGRESS,
  JUPYTER,
  KNATIVE,
  CERT_MANAGER,
  RUNNER,
  APPLICATION_INSTALLED_STATUSES,
} from '../constants';

const isApplicationInstalled = appStatus => APPLICATION_INSTALLED_STATUSES.includes(appStatus);

const applicationInitialState = {
  status: null,
  statusReason: null,
  requestReason: null,
  requestStatus: null,
  installed: false,
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
          upgradeAvailable: null,
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
        update_available: upgradeAvailable,
      } = serverAppEntry;

      this.state.applications[appId] = {
        ...(this.state.applications[appId] || {}),
        status,
        statusReason,
        installed: isApplicationInstalled(status),
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
        this.state.applications.runner.upgradeAvailable = upgradeAvailable;
      }
    });
  }
}
