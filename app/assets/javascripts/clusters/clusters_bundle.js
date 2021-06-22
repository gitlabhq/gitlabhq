import { GlToast } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import Vue from 'vue';
import createFlash from '~/flash';
import AccessorUtilities from '~/lib/utils/accessor';
import initProjectSelectDropdown from '~/project_select';
import Poll from '../lib/utils/poll';
import { s__ } from '../locale';
import PersistentUserCallout from '../persistent_user_callout';
import initSettingsPanels from '../settings_panels';
import RemoveClusterConfirmation from './components/remove_cluster_confirmation.vue';
import ClustersService from './services/clusters_service';
import ClustersStore from './stores/clusters_store';

const Environments = () => import('ee_component/clusters/components/environments.vue');

Vue.use(GlToast);

export default class Clusters {
  constructor() {
    const {
      statusPath,
      clusterEnvironmentsPath,
      hasRbac,
      providerType,
      clusterStatus,
      clusterStatusReason,
      helpPath,
      environmentsHelpPath,
      clustersHelpPath,
      deployBoardsHelpPath,
      clusterId,
    } = document.querySelector('.js-edit-cluster-form').dataset;

    this.clusterId = clusterId;
    this.clusterNewlyCreatedKey = `cluster_${this.clusterId}_newly_created`;
    this.clusterBannerDismissedKey = `cluster_${this.clusterId}_banner_dismissed`;

    this.store = new ClustersStore();
    this.store.setHelpPaths({
      helpPath,
      environmentsHelpPath,
      clustersHelpPath,
      deployBoardsHelpPath,
    });
    this.store.updateStatus(clusterStatus);
    this.store.updateStatusReason(clusterStatusReason);
    this.store.updateProviderType(providerType);
    this.store.updateRbac(hasRbac);
    this.service = new ClustersService({
      endpoint: statusPath,
      clusterEnvironmentsEndpoint: clusterEnvironmentsPath,
    });

    this.errorContainer = document.querySelector('.js-cluster-error');
    this.successContainer = document.querySelector('.js-cluster-success');
    this.creatingContainer = document.querySelector('.js-cluster-creating');
    this.unreachableContainer = document.querySelector('.js-cluster-api-unreachable');
    this.authenticationFailureContainer = document.querySelector(
      '.js-cluster-authentication-failure',
    );
    this.errorReasonContainer = this.errorContainer.querySelector('.js-error-reason');
    this.tokenField = document.querySelector('.js-cluster-token');

    initProjectSelectDropdown();
    Clusters.initDismissableCallout();
    initSettingsPanels();

    this.initEnvironments();

    if (clusterEnvironmentsPath && this.environments) {
      this.store.toggleFetchEnvironments(true);

      this.initPolling(
        'fetchClusterEnvironments',
        (data) => this.handleClusterEnvironmentsSuccess(data),
        () => this.handleEnvironmentsPollError(),
      );
    }

    this.updateContainer(null, this.store.state.status, this.store.state.statusReason);

    this.addListeners();
    if (statusPath && !this.environments) {
      this.initPolling(
        'fetchClusterStatus',
        (data) => this.handleClusterStatusSuccess(data),
        () => this.handlePollError(),
      );
    }

    this.initRemoveClusterActions();
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

  initRemoveClusterActions() {
    const el = document.querySelector('#js-cluster-remove-actions');
    if (el && el.dataset) {
      const { clusterName, clusterPath, hasManagementProject } = el.dataset;

      this.removeClusterAction = new Vue({
        el,
        render(createElement) {
          return createElement(RemoveClusterConfirmation, {
            props: {
              clusterName,
              clusterPath,
              hasManagementProject,
            },
          });
        },
      });
    }
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
    el.querySelector('.js-close').addEventListener('click', () => {
      el.classList.add('hidden');
      this.setBannerDismissedState(status, true);
    });
  }

  addListeners() {
    // Add event listener to all the banner close buttons
    this.addBannerCloseHandler(this.unreachableContainer, 'unreachable');
    this.addBannerCloseHandler(this.authenticationFailureContainer, 'authentication_failure');
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
    createFlash({
      message: s__('ClusterIntegration|Something went wrong on our end.'),
    });
  }

  handleClusterStatusSuccess(data) {
    const prevStatus = this.store.state.status;

    this.store.updateStateFromServer(data.data);

    this.updateContainer(prevStatus, this.store.state.status, this.store.state.statusReason);
  }

  hideAll() {
    this.errorContainer.classList.add('hidden');
    this.successContainer.classList.add('hidden');
    this.creatingContainer.classList.add('hidden');
    this.unreachableContainer.classList.add('hidden');
    this.authenticationFailureContainer.classList.add('hidden');
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

  destroy() {
    this.destroyed = true;

    if (this.poll) {
      this.poll.stop();
    }

    if (this.environments) {
      this.environments.$destroy();
    }
  }
}
