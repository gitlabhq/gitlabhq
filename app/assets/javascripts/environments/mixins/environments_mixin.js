/**
 * Common code between environmets app and folder view
 */
import _ from 'underscore';
import Visibility from 'visibilityjs';
import Poll from '../../lib/utils/poll';
import {
  getParameterByName,
} from '../../lib/utils/common_utils';
import { s__ } from '../../locale';
import Flash from '../../flash';
import eventHub from '../event_hub';

import EnvironmentsStore from '../stores/environments_store';
import EnvironmentsService from '../services/environments_service';
import tablePagination from '../../vue_shared/components/table_pagination.vue';
import environmentTable from '../components/environments_table.vue';
import tabs from '../../vue_shared/components/navigation_tabs.vue';
import container from '../components/container.vue';

export default {

  components: {
    environmentTable,
    container,
    tabs,
    tablePagination,
  },

  data() {
    const store = new EnvironmentsStore();

    return {
      store,
      state: store.state,
      isLoading: false,
      isMakingRequest: false,
      scope: getParameterByName('scope') || 'available',
      page: getParameterByName('page') || '1',
      requestData: {},
      environmentInStopModal: {},
    };
  },

  methods: {
    saveData(resp) {
      this.isLoading = false;

      if (_.isEqual(resp.config.params, this.requestData)) {
        this.store.storeAvailableCount(resp.data.available_count);
        this.store.storeStoppedCount(resp.data.stopped_count);
        this.store.storeEnvironments(resp.data.environments);
        this.store.setPagination(resp.headers);
      }
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
      return this.service.fetchEnvironments(this.requestData)
        .then(response => this.successCallback(response))
        .then(() => {
          // restart polling
          this.poll.restart({ data: this.requestData });
        })
        .catch(() => {
          this.errorCallback();

          // restart polling
          this.poll.restart();
        });
    },

    errorCallback() {
      this.isLoading = false;
      Flash(s__('Environments|An error occurred while fetching the environments.'));
    },

    postAction({ endpoint, errorMessage }) {
      if (!this.isMakingRequest) {
        this.isLoading = true;

        this.service.postAction(endpoint)
          .then(() => this.fetchEnvironments())
          .catch(() => {
            this.isLoading = false;
            Flash(errorMessage || s__('Environments|An error occurred while making the request.'));
          });
      }
    },

    fetchEnvironments() {
      this.isLoading = true;

      return this.service.fetchEnvironments(this.requestData)
        .then(this.successCallback)
        .catch(this.errorCallback);
    },

    updateStopModal(environment) {
      this.environmentInStopModal = environment;
    },

    stopEnvironment(environment) {
      const endpoint = environment.stop_path;
      const errorMessage = s__('Environments|An error occurred while stopping the environment, please try again');
      this.postAction({ endpoint, errorMessage });
    },
  },

  computed: {
    tabs() {
      return [
        {
          name: s__('Available'),
          scope: 'available',
          count: this.state.availableCounter,
          isActive: this.scope === 'available',
        },
        {
          name: s__('Stopped'),
          scope: 'stopped',
          count: this.state.stoppedCounter,
          isActive: this.scope === 'stopped',
        },
      ];
    },
  },

  /**
   * Fetches all the environments and stores them.
   * Toggles loading property.
   */
  created() {
    this.service = new EnvironmentsService(this.endpoint);
    this.requestData = { page: this.page, scope: this.scope };

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

    eventHub.$on('postAction', this.postAction);
    eventHub.$on('requestStopEnvironment', this.updateStopModal);
    eventHub.$on('stopEnvironment', this.stopEnvironment);
  },

  beforeDestroy() {
    eventHub.$off('postAction', this.postAction);
    eventHub.$off('requestStopEnvironment', this.updateStopModal);
    eventHub.$off('stopEnvironment', this.stopEnvironment);
  },
};
