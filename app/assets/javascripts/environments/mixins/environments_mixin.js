/**
 * Common code between environmets app and folder view
 */
import { isEqual, isFunction, omitBy } from 'lodash';
import Visibility from 'visibilityjs';
import { createAlert } from '~/alert';
import Poll from '~/lib/utils/poll';
import { getParameterByName } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import tabs from '~/vue_shared/components/navigation_tabs.vue';
import tablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import container from '../components/container.vue';
import environmentTable from '../components/environments_table.vue';
import eventHub from '../event_hub';

import EnvironmentsService from '../services/environments_service';
import EnvironmentsStore from '../stores/environments_store';

export default {
  components: {
    environmentTable,
    container,
    tabs,
    tablePagination,
  },

  data() {
    const store = new EnvironmentsStore();

    const isDetailView = document.body.contains(
      document.getElementById('environments-detail-view'),
    );

    return {
      store,
      state: store.state,
      isLoading: false,
      isMakingRequest: false,
      scope: getParameterByName('scope') || 'available',
      page: getParameterByName('page') || '1',
      requestData: {},
      environmentInStopModal: {},
      environmentInDeleteModal: {},
      environmentInRollbackModal: {},
      isDetailView,
    };
  },

  methods: {
    saveData(resp) {
      this.isLoading = false;

      // Prevent the absence of the nested flag from causing mismatches
      const response = this.filterNilValues(resp.config.params);
      const request = this.filterNilValues(this.requestData);

      if (isEqual(response, request)) {
        this.store.storeAvailableCount(resp.data.available_count);
        this.store.storeStoppedCount(resp.data.stopped_count);
        this.store.storeEnvironments(resp.data.environments);
        this.store.setReviewAppDetails(resp.data.review_app);
        this.store.setPagination(resp.headers);
      }
    },

    filterNilValues(obj) {
      return omitBy(obj, (value) => value === undefined || value === null);
    },

    /**
     * Handles URL and query parameter changes.
     * When the user uses the pagination or the tabs,
     *  - update URL
     *  - Make API request to the server with new parameters
     *  - Update the polling function
     *  - Update the internal state
     */
    updateContent(parameters) {
      this.updateInternalState(parameters);
      // fetch new data
      return this.service
        .fetchEnvironments(this.requestData)
        .then((response) => {
          this.successCallback(response);
          this.poll.enable({ data: this.requestData, response });
        })
        .catch(() => {
          this.errorCallback();

          // restart polling
          this.poll.restart();
        });
    },

    errorCallback() {
      this.isLoading = false;
      createAlert({
        message: s__('Environments|An error occurred while fetching the environments.'),
      });
    },

    postAction({
      endpoint,
      errorMessage = s__('Environments|An error occurred while making the request.'),
    }) {
      if (!this.isMakingRequest) {
        this.isLoading = true;

        this.service
          .postAction(endpoint)
          .then(() => {
            // Originally, the detail page buttons were implemented as <form>s that POSTed
            // to the server, which would naturally result in a page refresh.
            // When environment details page was converted to Vue, the buttons were updated to trigger
            // HTTP requests using `axios`, which did not cause a refresh on completion.
            // To preserve the original behavior, we manually reload the page when
            // network requests complete successfully.
            if (!this.isDetailView) {
              this.fetchEnvironments();
            } else {
              window.location.reload();
            }
          })
          .catch((err) => {
            this.isLoading = false;
            createAlert({
              message: isFunction(errorMessage) ? errorMessage(err.response.data) : errorMessage,
            });
          });
      }
    },

    fetchEnvironments() {
      this.isLoading = true;

      return this.service
        .fetchEnvironments(this.requestData)
        .then(this.successCallback)
        .catch(this.errorCallback);
    },

    updateStopModal(environment) {
      this.environmentInStopModal = environment;
    },

    updateDeleteModal(environment) {
      this.environmentInDeleteModal = environment;
    },

    updateRollbackModal(environment) {
      this.environmentInRollbackModal = environment;
    },

    stopEnvironment(environment) {
      const endpoint = environment.stop_path;
      const errorMessage = s__(
        'Environments|An error occurred while stopping the environment, please try again',
      );
      this.postAction({ endpoint, errorMessage });
    },

    deleteEnvironment(environment) {
      const endpoint = environment.delete_path;
      const { onSingleEnvironmentPage } = environment;
      const errorMessage = s__(
        'Environments|An error occurred while deleting the environment. Check if the environment stopped; if not, stop it and try again.',
      );

      this.service
        .deleteAction(endpoint)
        .then(() => {
          if (!onSingleEnvironmentPage) {
            // Reload as a first solution to bust the ETag cache
            window.location.reload();
            return;
          }
          const url = window.location.href.split('/');
          url.pop();
          window.location.href = url.join('/');
        })
        .catch(() => {
          createAlert({
            message: errorMessage,
          });
        });
    },

    rollbackEnvironment(environment) {
      const { retryUrl, isLastDeployment } = environment;
      const errorMessage = isLastDeployment
        ? s__('Environments|An error occurred while re-deploying the environment, please try again')
        : s__(
            'Environments|An error occurred while rolling back the environment, please try again',
          );
      this.postAction({ endpoint: retryUrl, errorMessage });
    },

    cancelAutoStop(autoStopPath) {
      const errorMessage = ({ message }) =>
        message ||
        s__('Environments|An error occurred while canceling the auto stop, please try again');
      this.postAction({ endpoint: autoStopPath, errorMessage });
    },
  },

  computed: {
    tabs() {
      return [
        {
          name: __('Available'),
          scope: 'available',
          count: this.state.availableCounter,
          isActive: this.scope === 'available',
        },
        {
          name: __('Stopped'),
          scope: 'stopped',
          count: this.state.stoppedCounter,
          isActive: this.scope === 'stopped',
        },
      ];
    },
    activeTab() {
      return this.tabs.findIndex(({ isActive }) => isActive) ?? 0;
    },
  },

  /**
   * Fetches all the environments and stores them.
   * Toggles loading property.
   */
  created() {
    this.service = new EnvironmentsService(this.endpoint);
    this.requestData = { page: this.page, scope: this.scope, nested: true };

    if (!this.isDetailView) {
      this.poll = new Poll({
        resource: this.service,
        method: 'fetchEnvironments',
        data: this.requestData,
        successCallback: this.successCallback,
        errorCallback: this.errorCallback,
        notificationCallback: (isMakingRequest) => {
          this.isMakingRequest = isMakingRequest;
        },
      });

      if (!Visibility.hidden()) {
        this.isLoading = true;
        this.poll.makeRequest();
      } else {
        this.fetchEnvironments();
      }

      Visibility.change(() => {
        if (!Visibility.hidden()) {
          this.poll.restart();
        } else {
          this.poll.stop();
        }
      });
    }

    eventHub.$on('postAction', this.postAction);

    eventHub.$on('requestStopEnvironment', this.updateStopModal);
    eventHub.$on('stopEnvironment', this.stopEnvironment);

    eventHub.$on('requestDeleteEnvironment', this.updateDeleteModal);
    eventHub.$on('deleteEnvironment', this.deleteEnvironment);

    eventHub.$on('requestRollbackEnvironment', this.updateRollbackModal);
    eventHub.$on('rollbackEnvironment', this.rollbackEnvironment);

    eventHub.$on('cancelAutoStop', this.cancelAutoStop);
  },

  beforeDestroy() {
    eventHub.$off('postAction', this.postAction);

    eventHub.$off('requestStopEnvironment', this.updateStopModal);
    eventHub.$off('stopEnvironment', this.stopEnvironment);

    eventHub.$off('requestDeleteEnvironment', this.updateDeleteModal);
    eventHub.$off('deleteEnvironment', this.deleteEnvironment);

    eventHub.$off('requestRollbackEnvironment', this.updateRollbackModal);
    eventHub.$off('rollbackEnvironment', this.rollbackEnvironment);

    eventHub.$off('cancelAutoStop', this.cancelAutoStop);
  },
};
