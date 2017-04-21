import Vue from 'vue';
import Visibility from 'visibilityjs';
import PipelinesTableComponent from '../../vue_shared/components/pipelines_table';
import PipelinesService from '../../pipelines/services/pipelines_service';
import PipelineStore from '../../pipelines/stores/pipelines_store';
import eventHub from '../../pipelines/event_hub';
import EmptyState from '../../pipelines/components/empty_state.vue';
import ErrorState from '../../pipelines/components/error_state.vue';
import '../../lib/utils/common_utils';
import '../../vue_shared/vue_resource_interceptor';
import Poll from '../../lib/utils/poll';

/**
 *
 * Uses `pipelines-table-component` to render Pipelines table with an API call.
 * Endpoint is provided in HTML and passed as `endpoint`.
 * We need a store to store the received environemnts.
 * We need a service to communicate with the server.
 *
 * Necessary SVG in the table are provided as props. This should be refactored
 * as soon as we have Webpack and can load them directly into JS files.
 */

export default Vue.component('pipelines-table', {

  components: {
    'pipelines-table-component': PipelinesTableComponent,
    'error-state': ErrorState,
    'empty-state': EmptyState,
  },

  /**
   * Accesses the DOM to provide the needed data.
   * Returns the necessary props to render `pipelines-table-component` component.
   *
   * @return {Object}
   */
  data() {
    const store = new PipelineStore();

    return {
      endpoint: null,
      helpPagePath: null,
      store,
      state: store.state,
      isLoading: false,
      hasError: false,
      isMakingRequest: false,
    };
  },

  computed: {
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },

    shouldRenderEmptyState() {
      return !this.state.pipelines.length &&
        !this.isLoading &&
        !this.hasError;
    },

    shouldRenderTable() {
      return !this.isLoading &&
        this.state.pipelines.length > 0 &&
        !this.hasError;
    },
  },

  /**
   * When the component is about to be mounted, tell the service to fetch the data
   *
   * A request to fetch the pipelines will be made.
   * In case of a successfull response we will store the data in the provided
   * store, in case of a failed response we need to warn the user.
   *
   */
  beforeMount() {
    const element = document.querySelector('#commit-pipeline-table-view');

    this.endpoint = element.dataset.endpoint;
    this.helpPagePath = element.dataset.helpPagePath;
    this.service = new PipelinesService(this.endpoint);

    this.poll = new Poll({
      resource: this.service,
      method: 'getPipelines',
      successCallback: this.successCallback,
      errorCallback: this.errorCallback,
      notificationCallback: this.setIsMakingRequest,
    });

    if (!Visibility.hidden()) {
      this.poll.makeRequest();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });

    eventHub.$on('refreshPipelines', this.fetchPipelines);
  },

  beforeUpdate() {
    if (this.state.pipelines.length &&
        this.$children &&
        !this.isMakingRequest &&
        !this.isLoading) {
      this.store.startTimeAgoLoops.call(this, Vue);
    }
  },

  beforeDestroyed() {
    eventHub.$off('refreshPipelines');
  },

  destroyed() {
    this.poll.stop();
  },

  methods: {
    fetchPipelines() {
      return this.service.getPipelines()
        .then(response => this.successCallback(response))
        .catch(() => this.errorCallback());
    },

    successCallback(resp) {
      const response = resp.json();

      // depending of the endpoint the response can either bring a `pipelines` key or not.
      const pipelines = response.pipelines || response;
      this.store.storePipelines(pipelines);
      this.isLoading = false;
    },

    errorCallback() {
      this.hasError = true;
      this.isLoading = false;
    },

    setIsMakingRequest(isMakingRequest) {
      this.isMakingRequest = isMakingRequest;
    },
  },

  template: `
    <div class="content-list pipelines">
      <div
        class="realtime-loading"
        v-if="isLoading">
        <i
          class="fa fa-spinner fa-spin"
          aria-hidden="true" />
      </div>

      <empty-state
        v-if="shouldRenderEmptyState"
        :help-page-path="helpPagePath" />

      <error-state v-if="shouldRenderErrorState" />

      <div
        class="table-holder"
        v-if="shouldRenderTable">
        <pipelines-table-component
          :pipelines="state.pipelines"
          :service="service" />
      </div>
    </div>
  `,
});
