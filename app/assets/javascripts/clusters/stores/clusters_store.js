import { s__ } from '../../locale';
import { parseBoolean } from '../../lib/utils/common_utils';
import { INGRESS, JUPYTER, KNATIVE, CERT_MANAGER, RUNNER } from '../constants';

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
          title: s__('ClusterIntegration|Helm Tiller'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
        },
        ingress: {
          title: s__('ClusterIntegration|Ingress'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
          externalIp: null,
          externalHostname: null,
        },
        cert_manager: {
          title: s__('ClusterIntegration|Cert-Manager'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
          email: null,
        },
        runner: {
          title: s__('ClusterIntegration|GitLab Runner'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
          version: null,
          chartRepo: 'https://gitlab.com/charts/gitlab-runner',
          upgradeAvailable: null,
        },
        prometheus: {
          title: s__('ClusterIntegration|Prometheus'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
        },
        jupyter: {
          title: s__('ClusterIntegration|JupyterHub'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
          hostname: null,
        },
        knative: {
          title: s__('ClusterIntegration|Knative'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
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
