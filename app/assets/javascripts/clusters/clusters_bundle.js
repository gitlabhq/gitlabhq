import Visibility from 'visibilityjs';
import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import AccessorUtilities from '~/lib/utils/accessor';
import PersistentUserCallout from '../persistent_user_callout';
import { s__, sprintf } from '../locale';
import Flash from '../flash';
import Poll from '../lib/utils/poll';
import initSettingsPanels from '../settings_panels';
import eventHub from './event_hub';
import { APPLICATION_STATUS, INGRESS, INGRESS_DOMAIN_SUFFIX, CROSSPLANE } from './constants';
import ClustersService from './services/clusters_service';
import ClustersStore from './stores/clusters_store';
import Applications from './components/applications.vue';
import setupToggleButtons from '../toggle_buttons';
import initProjectSelectDropdown from '~/project_select';

const Environments = () => import('ee_component/clusters/components/environments.vue');

Vue.use(GlToast);

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
      installElasticStackPath,
      installCrossplanePath,
      installPrometheusPath,
      managePrometheusPath,
      clusterEnvironmentsPath,
      hasRbac,
      providerType,
      preInstalledKnative,
      clusterType,
      clusterStatus,
      clusterStatusReason,
      helpPath,
      ingressHelpPath,
      ingressDnsHelpPath,
      environmentsHelpPath,
      clustersHelpPath,
      deployBoardsHelpPath,
      cloudRunHelpPath,
      clusterId,
    } = document.querySelector('.js-edit-cluster-form').dataset;

    this.clusterId = clusterId;
    this.clusterNewlyCreatedKey = `cluster_${this.clusterId}_newly_created`;
    this.clusterBannerDismissedKey = `cluster_${this.clusterId}_banner_dismissed`;

    this.store = new ClustersStore();
    this.store.setHelpPaths(
      helpPath,
      ingressHelpPath,
      ingressDnsHelpPath,
      environmentsHelpPath,
      clustersHelpPath,
      deployBoardsHelpPath,
      cloudRunHelpPath,
    );
    this.store.setManagePrometheusPath(managePrometheusPath);
    this.store.updateStatus(clusterStatus);
    this.store.updateStatusReason(clusterStatusReason);
    this.store.updateProviderType(providerType);
    this.store.updatePreInstalledKnative(preInstalledKnative);
    this.store.updateRbac(hasRbac);
    this.service = new ClustersService({
      endpoint: statusPath,
      installHelmEndpoint: installHelmPath,
      installIngressEndpoint: installIngressPath,
      installCertManagerEndpoint: installCertManagerPath,
      installCrossplaneEndpoint: installCrossplanePath,
      installRunnerEndpoint: installRunnerPath,
      installPrometheusEndpoint: installPrometheusPath,
      installJupyterEndpoint: installJupyterPath,
      installKnativeEndpoint: installKnativePath,
      updateKnativeEndpoint: updateKnativePath,
      installElasticStackEndpoint: installElasticStackPath,
      clusterEnvironmentsEndpoint: clusterEnvironmentsPath,
    });

    this.installApplication = this.installApplication.bind(this);
    this.showToken = this.showToken.bind(this);

    this.errorContainer = document.querySelector('.js-cluster-error');
    this.successContainer = document.querySelector('.js-cluster-success');
    this.creatingContainer = document.querySelector('.js-cluster-creating');
    this.unreachableContainer = document.querySelector('.js-cluster-api-unreachable');
    this.authenticationFailureContainer = document.querySelector(
      '.js-cluster-authentication-failure',
    );
    this.errorReasonContainer = this.errorContainer.querySelector('.js-error-reason');
    this.successApplicationContainer = document.querySelector('.js-cluster-application-notice');
    this.showTokenButton = document.querySelector('.js-show-cluster-token');
    this.tokenField = document.querySelector('.js-cluster-token');
    this.ingressDomainHelpText = document.querySelector('.js-ingress-domain-help-text');
    this.ingressDomainSnippet =
      this.ingressDomainHelpText &&
      this.ingressDomainHelpText.querySelector('.js-ingress-domain-snippet');

    initProjectSelectDropdown();
    Clusters.initDismissableCallout();
    initSettingsPanels();

    const toggleButtonsContainer = document.querySelector('.js-cluster-enable-toggle-area');
    if (toggleButtonsContainer) {
      setupToggleButtons(toggleButtonsContainer);
    }
    this.initApplications(clusterType);
    this.initEnvironments();

    if (clusterEnvironmentsPath && this.environments) {
      this.store.toggleFetchEnvironments(true);

      this.initPolling(
        'fetchClusterEnvironments',
        data => this.handleClusterEnvironmentsSuccess(data),
        () => this.handleEnvironmentsPollError(),
      );
    }

    this.updateContainer(null, this.store.state.status, this.store.state.statusReason);

    this.addListeners();
    if (statusPath && !this.environments) {
      this.initPolling(
        'fetchClusterStatus',
        data => this.handleClusterStatusSuccess(data),
        () => this.handlePollError(),
      );
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
            cloudRunHelpPath: this.state.cloudRunHelpPath,
            providerType: this.state.providerType,
            preInstalledKnative: this.state.preInstalledKnative,
            rbac: this.state.rbac,
          },
        });
      },
    });
  }

  initEnvironments() {
    const { store } = this;
    const el = document.querySelector('#js-cluster-environments');

    if (!el) {
      return;
    }

    this.environments = new Vue({
      el,
      data() {
        return {
          state: store.state,
        };
      },
      render(createElement) {
        return createElement(Environments, {
          props: {
            isFetching: this.state.fetchingEnvironments,
            environments: this.state.environments,
            environmentsHelpPath: this.state.environmentsHelpPath,
            clustersHelpPath: this.state.clustersHelpPath,
            deployBoardsHelpPath: this.state.deployBoardsHelpPath,
          },
        });
      },
    });
  }

  handleClusterEnvironmentsSuccess(data) {
    this.store.toggleFetchEnvironments(false);
    this.store.updateEnvironments(data.data);
  }

  static initDismissableCallout() {
    const callout = document.querySelector('.js-cluster-security-warning');
    PersistentUserCallout.factory(callout);
  }

  addBannerCloseHandler(el, status) {
    el.querySelector('.js-close-banner').addEventListener('click', () => {
      el.classList.add('hidden');
      this.setBannerDismissedState(status, true);
    });
  }

  addListeners() {
    if (this.showTokenButton) this.showTokenButton.addEventListener('click', this.showToken);
    eventHub.$on('installApplication', this.installApplication);
    eventHub.$on('updateApplication', data => this.updateApplication(data));
    eventHub.$on('saveKnativeDomain', data => this.saveKnativeDomain(data));
    eventHub.$on('setKnativeHostname', data => this.setKnativeHostname(data));
    eventHub.$on('uninstallApplication', data => this.uninstallApplication(data));
    eventHub.$on('setCrossplaneProviderStack', data => this.setCrossplaneProviderStack(data));
    // Add event listener to all the banner close buttons
    this.addBannerCloseHandler(this.unreachableContainer, 'unreachable');
    this.addBannerCloseHandler(this.authenticationFailureContainer, 'authentication_failure');
  }

  removeListeners() {
    if (this.showTokenButton) this.showTokenButton.removeEventListener('click', this.showToken);
    eventHub.$off('installApplication', this.installApplication);
    eventHub.$off('updateApplication', this.updateApplication);
    eventHub.$off('saveKnativeDomain');
    eventHub.$off('setKnativeHostname');
    eventHub.$off('setCrossplaneProviderStack');
    eventHub.$off('uninstallApplication');
  }

  initPolling(method, successCallback, errorCallback) {
    this.poll = new Poll({
      resource: this.service,
      method,
      successCallback,
      errorCallback,
    });

    if (!Visibility.hidden()) {
      this.poll.makeRequest();
    }

    Visibility.change(() => {
      if (!Visibility.hidden() && !this.destroyed) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });
  }

  handlePollError() {
    this.constructor.handleError();
  }

  handleEnvironmentsPollError() {
    this.store.toggleFetchEnvironments(false);

    this.handlePollError();
  }

  static handleError() {
    Flash(s__('ClusterIntegration|Something went wrong on our end.'));
  }

  handleClusterStatusSuccess(data) {
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
    this.unreachableContainer.classList.add('hidden');
    this.authenticationFailureContainer.classList.add('hidden');
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

  setBannerDismissedState(status, isDismissed) {
    if (AccessorUtilities.isLocalStorageAccessSafe()) {
      window.localStorage.setItem(this.clusterBannerDismissedKey, `${status}_${isDismissed}`);
    }
  }

  isBannerDismissed(status) {
    let bannerState;
    if (AccessorUtilities.isLocalStorageAccessSafe()) {
      bannerState = window.localStorage.getItem(this.clusterBannerDismissedKey);
    }

    return bannerState === `${status}_true`;
  }

  setClusterNewlyCreated(state) {
    if (AccessorUtilities.isLocalStorageAccessSafe()) {
      window.localStorage.setItem(this.clusterNewlyCreatedKey, Boolean(state));
    }
  }

  isClusterNewlyCreated() {
    // once this is true, it will always be true for a given page load
    if (!this.isNewlyCreated) {
      let newlyCreated;
      if (AccessorUtilities.isLocalStorageAccessSafe()) {
        newlyCreated = window.localStorage.getItem(this.clusterNewlyCreatedKey);
      }

      this.isNewlyCreated = newlyCreated === 'true';
    }
    return this.isNewlyCreated;
  }

  updateContainer(prevStatus, status, error) {
    if (status !== 'created' && this.isBannerDismissed(status)) {
      return;
    }
    this.setBannerDismissedState(status, false);

    if (prevStatus !== status) {
      this.hideAll();

      switch (status) {
        case 'created':
          if (this.isClusterNewlyCreated()) {
            this.setClusterNewlyCreated(false);
            this.successContainer.classList.remove('hidden');
          } else if (prevStatus) {
            this.setClusterNewlyCreated(true);
            window.location.reload();
          }
          break;
        case 'errored':
          this.errorContainer.classList.remove('hidden');
          this.errorReasonContainer.textContent = error;
          break;
        case 'unreachable':
          this.unreachableContainer.classList.remove('hidden');
          break;
        case 'authentication_failure':
          this.authenticationFailureContainer.classList.remove('hidden');
          break;
        case 'scheduled':
        case 'creating':
          this.creatingContainer.classList.remove('hidden');
          break;
        default:
      }
    }
  }

  installApplication({ id: appId, params }) {
    return Clusters.validateInstallation(appId, params)
      .then(() => {
        this.store.updateAppProperty(appId, 'requestReason', null);
        this.store.updateAppProperty(appId, 'statusReason', null);
        this.store.installApplication(appId);

        // eslint-disable-next-line promise/no-nesting
        this.service.installApplication(appId, params).catch(() => {
          this.store.notifyInstallFailure(appId);
          this.store.updateAppProperty(
            appId,
            'requestReason',
            s__('ClusterIntegration|Request to begin installing failed'),
          );
        });
      })
      .catch(error => this.store.updateAppProperty(appId, 'validationError', error));
  }

  static validateInstallation(appId, params) {
    return new Promise((resolve, reject) => {
      if (appId === CROSSPLANE && !params.stack) {
        reject(s__('ClusterIntegration|Select a stack to install Crossplane.'));
        return;
      }

      resolve();
    });
  }

  uninstallApplication({ id: appId }) {
    this.store.updateAppProperty(appId, 'requestReason', null);
    this.store.updateAppProperty(appId, 'statusReason', null);

    this.store.uninstallApplication(appId);

    return this.service.uninstallApplication(appId).catch(() => {
      this.store.notifyUninstallFailure(appId);
      this.store.updateAppProperty(
        appId,
        'requestReason',
        s__('ClusterIntegration|Request to begin uninstalling failed'),
      );
    });
  }

  updateApplication({ id: appId, params }) {
    this.store.updateApplication(appId);
    this.service.installApplication(appId, params).catch(() => {
      this.store.notifyUpdateFailure(appId);
    });
  }

  toggleIngressDomainHelpText({ externalIp }, { externalIp: newExternalIp }) {
    if (externalIp !== newExternalIp) {
      this.ingressDomainHelpText.classList.toggle('hide', !newExternalIp);
      this.ingressDomainSnippet.textContent = `${newExternalIp}${INGRESS_DOMAIN_SUFFIX}`;
    }
  }

  saveKnativeDomain(data) {
    const appId = data.id;
    this.store.updateApplication(appId);
    this.service.updateApplication(appId, data.params).catch(() => {
      this.store.notifyUpdateFailure(appId);
    });
  }

  setKnativeHostname(data) {
    const appId = data.id;
    this.store.updateAppProperty(appId, 'isEditingHostName', true);
    this.store.updateAppProperty(appId, 'hostname', data.hostname);
  }

  setCrossplaneProviderStack(data) {
    const appId = data.id;
    this.store.updateAppProperty(appId, 'stack', data.stack.code);
    this.store.updateAppProperty(appId, 'validationError', null);
  }

  destroy() {
    this.destroyed = true;

    this.removeListeners();

    if (this.poll) {
      this.poll.stop();
    }

    if (this.environments) {
      this.environments.$destroy();
    }

    this.applications.$destroy();
  }
}
