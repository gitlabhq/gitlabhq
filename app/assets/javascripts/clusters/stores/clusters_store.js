import { s__ } from '../../locale';
import { INGRESS } from '../constants';

export default class ClusterStore {
  constructor() {
    this.state = {
      helpPath: null,
      ingressHelpPath: null,
      status: null,
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
        },
        runner: {
          title: s__('ClusterIntegration|GitLab Runner'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
        },
        prometheus: {
          title: s__('ClusterIntegration|Prometheus'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
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

  updateStatusReason(reason) {
    this.state.statusReason = reason;
  }

  updateAppProperty(appId, prop, value) {
    this.state.applications[appId][prop] = value;
  }

  updateStateFromServer(serverState = {}) {
    this.state.status = serverState.status;
    this.state.statusReason = serverState.status_reason;

    serverState.applications.forEach((serverAppEntry) => {
      const {
        name: appId,
        status,
        status_reason: statusReason,
      } = serverAppEntry;

      this.state.applications[appId] = {
        ...(this.state.applications[appId] || {}),
        status,
        statusReason,
      };

      if (appId === INGRESS) {
        this.state.applications.ingress.externalIp = serverAppEntry.external_ip;
      }
    });
  }
}
