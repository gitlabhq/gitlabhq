import Visibility from 'visibilityjs';
import Vue from 'vue';
import PersistentUserCallout from '../persistent_user_callout';
import { s__, sprintf } from '../locale';
import Flash from '../flash';
import Poll from '../lib/utils/poll';
import initSettingsPanels from '../settings_panels';
import eventHub from './event_hub';
import {
  APPLICATION_STATUS,
  REQUEST_SUBMITTED,
  REQUEST_FAILURE,
  UPGRADE_REQUESTED,
  UPGRADE_REQUEST_FAILURE,
  INGRESS,
  INGRESS_DOMAIN_SUFFIX,
} from './constants';
import ClustersService from './services/clusters_service';
import ClustersStore from './stores/clusters_store';
import Applications from './components/applications.vue';
import setupToggleButtons from '../toggle_buttons';

/**
 * Cluster page has 2 separate parts:
 * Toggle button and applications section
 *
 * - Polling status while creating or scheduled
 * - Update status area with the response result
 */

export default class Clusters {
  constructor() {
    const {
      statusPath,
      installHelmPath,
      installIngressPath,
      installCertManagerPath,
      installRunnerPath,
      installJupyterPath,
      installKnativePath,
      updateKnativePath,
      installPrometheusPath,
      managePrometheusPath,
      hasRbac,
      clusterType,
      clusterStatus,
      clusterStatusReason,
      helpPath,
      ingressHelpPath,
      ingressDnsHelpPath,
    } = document.querySelector('.js-edit-cluster-form').dataset;

    this.store = new ClustersStore();
    this.store.setHelpPaths(helpPath, ingressHelpPath, ingressDnsHelpPath);
    this.store.setManagePrometheusPath(managePrometheusPath);
    this.store.updateStatus(clusterStatus);
    this.store.updateStatusReason(clusterStatusReason);
    this.store.updateRbac(hasRbac);
    this.service = new ClustersService({
      endpoint: statusPath,
      installHelmEndpoint: installHelmPath,
      installIngressEndpoint: installIngressPath,
      installCertManagerEndpoint: installCertManagerPath,
      installRunnerEndpoint: installRunnerPath,
      installPrometheusEndpoint: installPrometheusPath,
      installJupyterEndpoint: installJupyterPath,
      installKnativeEndpoint: installKnativePath,
      updateKnativeEndpoint: updateKnativePath,
    });

    this.installApplication = this.installApplication.bind(this);
    this.showToken = this.showToken.bind(this);

    this.errorContainer = document.querySelector('.js-cluster-error');
    this.successContainer = document.querySelector('.js-cluster-success');
    this.creatingContainer = document.querySelector('.js-cluster-creating');
    this.errorReasonContainer = this.errorContainer.querySelector('.js-error-reason');
    this.successApplicationContainer = document.querySelector('.js-cluster-application-notice');
    this.showTokenButton = document.querySelector('.js-show-cluster-token');
    this.tokenField = document.querySelector('.js-cluster-token');
    this.ingressDomainHelpText = document.querySelector('.js-ingress-domain-help-text');
    this.ingressDomainSnippet = this.ingressDomainHelpText.querySelector(
      '.js-ingress-domain-snippet',
    );

    Clusters.initDismissableCallout();
    initSettingsPanels();
    setupToggleButtons(document.querySelector('.js-cluster-enable-toggle-area'));
    this.initApplications(clusterType);

    if (this.store.state.status !== 'created') {
      this.updateContainer(null, this.store.state.status, this.store.state.statusReason);
    }

    this.addListeners();
    if (statusPath) {
      this.initPolling();
    }
  }

  initApplications(type) {
    const { store } = this;
    const el = document.querySelector('#js-cluster-applications');

    this.applications = new Vue({
      el,
      data() {
        return {
          state: store.state,
        };
      },
      render(createElement) {
        return createElement(Applications, {
          props: {
            type,
            applications: this.state.applications,
            helpPath: this.state.helpPath,
            ingressHelpPath: this.state.ingressHelpPath,
            managePrometheusPath: this.state.managePrometheusPath,
            ingressDnsHelpPath: this.state.ingressDnsHelpPath,
            rbac: this.state.rbac,
          },
        });
      },
    });
  }

  static initDismissableCallout() {
    const callout = document.querySelector('.js-cluster-security-warning');
    PersistentUserCallout.factory(callout);
  }

  addListeners() {
    if (this.showTokenButton) this.showTokenButton.addEventListener('click', this.showToken);
    eventHub.$on('installApplication', this.installApplication);
    eventHub.$on('upgradeApplication', data => this.upgradeApplication(data));
    eventHub.$on('upgradeFailed', appId => this.upgradeFailed(appId));
    eventHub.$on('dismissUpgradeSuccess', appId => this.dismissUpgradeSuccess(appId));
    eventHub.$on('saveKnativeDomain', data => this.saveKnativeDomain(data));
    eventHub.$on('setKnativeHostname', data => this.setKnativeHostname(data));
  }

  removeListeners() {
    if (this.showTokenButton) this.showTokenButton.removeEventListener('click', this.showToken);
    eventHub.$off('installApplication', this.installApplication);
    eventHub.$off('upgradeApplication', this.upgradeApplication);
    eventHub.$off('upgradeFailed', this.upgradeFailed);
    eventHub.$off('dismissUpgradeSuccess', this.dismissUpgradeSuccess);
    eventHub.$off('saveKnativeDomain');
    eventHub.$off('setKnativeHostname');
  }

  initPolling() {
    this.poll = new Poll({
      resource: this.service,
      method: 'fetchData',
      successCallback: data => this.handleSuccess(data),
      errorCallback: () => Clusters.handleError(),
    });

    if (!Visibility.hidden()) {
      this.poll.makeRequest();
    } else {
      this.service
        .fetchData()
        .then(data => this.handleSuccess(data))
        .catch(() => Clusters.handleError());
    }

    Visibility.change(() => {
      if (!Visibility.hidden() && !this.destroyed) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });
  }

  static handleError() {
    Flash(s__('ClusterIntegration|Something went wrong on our end.'));
  }

  handleSuccess(data) {
    const prevStatus = this.store.state.status;
    const prevApplicationMap = Object.assign({}, this.store.state.applications);

    this.store.updateStateFromServer(data.data);

    this.checkForNewInstalls(prevApplicationMap, this.store.state.applications);
    this.updateContainer(prevStatus, this.store.state.status, this.store.state.statusReason);
    this.toggleIngressDomainHelpText(
      prevApplicationMap[INGRESS],
      this.store.state.applications[INGRESS],
    );
  }

  showToken() {
    const type = this.tokenField.getAttribute('type');

    if (type === 'password') {
      this.tokenField.setAttribute('type', 'text');
      this.showTokenButton.textContent = s__('ClusterIntegration|Hide');
    } else {
      this.tokenField.setAttribute('type', 'password');
      this.showTokenButton.textContent = s__('ClusterIntegration|Show');
    }
  }

  hideAll() {
    this.errorContainer.classList.add('hidden');
    this.successContainer.classList.add('hidden');
    this.creatingContainer.classList.add('hidden');
  }

  checkForNewInstalls(prevApplicationMap, newApplicationMap) {
    const appTitles = Object.keys(newApplicationMap)
      .filter(
        appId =>
          newApplicationMap[appId].status === APPLICATION_STATUS.INSTALLED &&
          prevApplicationMap[appId].status !== APPLICATION_STATUS.INSTALLED &&
          prevApplicationMap[appId].status !== null,
      )
      .map(appId => newApplicationMap[appId].title);

    if (appTitles.length > 0) {
      const text = sprintf(
        s__('ClusterIntegration|%{appList} was successfully installed on your Kubernetes cluster'),
        {
          appList: appTitles.join(', '),
        },
      );
      Flash(text, 'notice', this.successApplicationContainer);
    }
  }

  updateContainer(prevStatus, status, error) {
    this.hideAll();

    // We poll all the time but only want the `created` banner to show when newly created
    if (this.store.state.status !== 'created' || prevStatus !== this.store.state.status) {
      switch (status) {
        case 'created':
          this.successContainer.classList.remove('hidden');
          break;
        case 'errored':
          this.errorContainer.classList.remove('hidden');
          this.errorReasonContainer.textContent = error;
          break;
        case 'scheduled':
        case 'creating':
          this.creatingContainer.classList.remove('hidden');
          break;
        default:
          this.hideAll();
      }
    }
  }

  installApplication(data) {
    const appId = data.id;
    this.store.updateAppProperty(appId, 'requestStatus', REQUEST_SUBMITTED);
    this.store.updateAppProperty(appId, 'requestReason', null);
    this.store.updateAppProperty(appId, 'statusReason', null);

    this.service.installApplication(appId, data.params).catch(() => {
      this.store.updateAppProperty(appId, 'requestStatus', REQUEST_FAILURE);
      this.store.updateAppProperty(
        appId,
        'requestReason',
        s__('ClusterIntegration|Request to begin installing failed'),
      );
    });
  }

  upgradeApplication(data) {
    const appId = data.id;
    this.store.updateAppProperty(appId, 'requestStatus', UPGRADE_REQUESTED);
    this.store.updateAppProperty(appId, 'status', APPLICATION_STATUS.UPDATING);
    this.service.installApplication(appId, data.params).catch(() => this.upgradeFailed(appId));
  }

  upgradeFailed(appId) {
    this.store.updateAppProperty(appId, 'requestStatus', UPGRADE_REQUEST_FAILURE);
  }

  dismissUpgradeSuccess(appId) {
    this.store.updateAppProperty(appId, 'requestStatus', null);
  }

  toggleIngressDomainHelpText(ingressPreviousState, ingressNewState) {
    const helpTextHidden = ingressNewState.status !== APPLICATION_STATUS.INSTALLED;
    const domainSnippetText = `${ingressNewState.externalIp}${INGRESS_DOMAIN_SUFFIX}`;

    if (ingressPreviousState.status !== ingressNewState.status) {
      this.ingressDomainHelpText.classList.toggle('hide', helpTextHidden);
      this.ingressDomainSnippet.textContent = domainSnippetText;
    }
  }

  saveKnativeDomain(data) {
    const appId = data.id;
    this.store.updateAppProperty(appId, 'status', APPLICATION_STATUS.UPDATING);
    this.service.updateApplication(appId, data.params);
  }

  setKnativeHostname(data) {
    const appId = data.id;
    this.store.updateAppProperty(appId, 'isEditingHostName', true);
    this.store.updateAppProperty(appId, 'hostname', data.hostname);
  }

  destroy() {
    this.destroyed = true;

    this.removeListeners();

    if (this.poll) {
      this.poll.stop();
    }

    this.applications.$destroy();
  }
}
