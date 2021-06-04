import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import { historyPushState, buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';
import { validateParams } from '~/pipelines/utils';
import { CANCEL_REQUEST } from '../constants';
import eventHub from '../event_hub';

export default {
  data() {
    return {
      isLoading: false,
      hasError: false,
      isMakingRequest: false,
      updateGraphDropdown: false,
      hasMadeRequest: false,
    };
  },
  computed: {
    shouldRenderPagination() {
      return !this.isLoading;
    },
  },
  beforeMount() {
    this.poll = new Poll({
      resource: this.service,
      method: 'getPipelines',
      data: this.requestData ? this.requestData : undefined,
      successCallback: this.successCallback,
      errorCallback: this.errorCallback,
      notificationCallback: this.setIsMakingRequest,
    });

    if (!Visibility.hidden()) {
      this.isLoading = true;
      this.poll.makeRequest();
    } else {
      // If tab is not visible we need to make the first request so we don't show the empty
      // state without knowing if there are any pipelines
      this.fetchPipelines();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });

    eventHub.$on('postAction', this.postAction);
    eventHub.$on('retryPipeline', this.postAction);
    eventHub.$on('clickedDropdown', this.updateTable);
    eventHub.$on('updateTable', this.updateTable);
    eventHub.$on('refreshPipelinesTable', this.fetchPipelines);
    eventHub.$on('runMergeRequestPipeline', this.runMergeRequestPipeline);
  },
  beforeDestroy() {
    eventHub.$off('postAction', this.postAction);
    eventHub.$off('retryPipeline', this.postAction);
    eventHub.$off('clickedDropdown', this.updateTable);
    eventHub.$off('updateTable', this.updateTable);
    eventHub.$off('refreshPipelinesTable', this.fetchPipelines);
    eventHub.$off('runMergeRequestPipeline', this.runMergeRequestPipeline);
  },
  destroyed() {
    this.poll.stop();
  },
  methods: {
    updateInternalState(parameters) {
      this.poll.stop();

      const queryString = Object.keys(parameters)
        .map((parameter) => {
          const value = parameters[parameter];
          // update internal state for UI
          this[parameter] = value;
          return `${parameter}=${encodeURIComponent(value)}`;
        })
        .join('&');

      // update polling parameters
      this.requestData = parameters;

      historyPushState(buildUrlWithCurrentLocation(`?${queryString}`));

      this.isLoading = true;
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
        .getPipelines(this.requestData)
        .then((response) => {
          this.isLoading = false;
          this.successCallback(response);

          this.poll.enable({ data: this.requestData, response });
        })
        .catch(() => {
          this.isLoading = false;
          this.errorCallback();

          // restart polling
          this.poll.restart({ data: this.requestData });
        });
    },
    updateTable() {
      // Cancel ongoing request
      if (this.isMakingRequest) {
        this.service.cancelationSource.cancel(CANCEL_REQUEST);
      }
      // Stop polling
      this.poll.stop();
      // Restarting the poll also makes an initial request
      return this.poll.restart();
    },
    fetchPipelines() {
      if (!this.isMakingRequest) {
        this.isLoading = true;

        this.getPipelines();
      }
    },
    getPipelines() {
      return this.service
        .getPipelines(this.requestData)
        .then((response) => this.successCallback(response))
        .catch((error) => this.errorCallback(error));
    },
    setCommonData(pipelines) {
      this.store.storePipelines(pipelines);
      this.isLoading = false;
      this.updateGraphDropdown = true;
      this.hasMadeRequest = true;

      // In case the previous polling request returned an error, we need to reset it
      if (this.hasError) {
        this.hasError = false;
      }
    },
    errorCallback(error) {
      this.hasMadeRequest = true;
      this.isLoading = false;

      if (error && error.message && error.message !== CANCEL_REQUEST) {
        this.hasError = true;
        this.updateGraphDropdown = false;
      }
    },
    setIsMakingRequest(isMakingRequest) {
      this.isMakingRequest = isMakingRequest;

      if (isMakingRequest) {
        this.updateGraphDropdown = false;
      }
    },
    postAction(endpoint) {
      this.service
        .postAction(endpoint)
        .then(() => this.updateTable())
        .catch(() =>
          createFlash({
            message: __('An error occurred while making the request.'),
          }),
        );
    },

    /**
     * When the user clicks on the run pipeline button
     * we toggle the state of the button to be disabled
     *
     * Once the post request has finished, we fetch the
     * pipelines again to show the most recent data
     *
     * Once the pipeline has been updated, we toggle back the
     * loading state and re-enable the run pipeline button
     */
    runMergeRequestPipeline(options) {
      this.store.toggleIsRunningPipeline(true);

      this.service
        .runMRPipeline(options)
        .then(() => this.updateTable())
        .catch(() => {
          createFlash({
            message: __(
              'An error occurred while trying to run a new pipeline for this merge request.',
            ),
          });
        })
        .finally(() => this.store.toggleIsRunningPipeline(false));
    },
    onChangePage(page) {
      /* URLS parameters are strings, we need to parse to match types */
      let params = {
        page: Number(page).toString(),
      };

      if (this.scope) {
        params.scope = this.scope;
      }

      params = this.onChangeWithFilter(params);

      this.updateContent(params);
    },

    onChangeWithFilter(params) {
      return { ...params, ...validateParams(this.requestData) };
    },
  },
};
