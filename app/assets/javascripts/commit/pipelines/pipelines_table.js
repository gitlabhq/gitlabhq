import Vue from 'vue';
import PipelinesTableComponent from '../../vue_shared/components/pipelines_table';
import PipelinesService from '../../vue_pipelines_index/services/pipelines_service';
import PipelineStore from '../../vue_pipelines_index/stores/pipelines_store';
import eventHub from '../../vue_pipelines_index/event_hub';
import EmptyState from '../../vue_pipelines_index/components/empty_state';
import ErrorState from '../../vue_pipelines_index/components/error_state';
import '../../lib/utils/common_utils';
import '../../vue_shared/vue_resource_interceptor';

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
    const pipelinesTableData = document.querySelector('#commit-pipeline-table-view').dataset;
    const store = new PipelineStore();

    return {
      endpoint: pipelinesTableData.endpoint,
      helpPagePath: pipelinesTableData.helpPagePath,
      store,
      state: store.state,
      isLoading: false,
      hasError: false,
    };
  },

  computed: {
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },

    shouldRenderEmptyState() {
      return !this.state.pipelines.length && !this.isLoading;
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
    this.service = new PipelinesService(this.endpoint);

    this.fetchPipelines();

    eventHub.$on('refreshPipelines', this.fetchPipelines);
  },

  beforeUpdate() {
    if (this.state.pipelines.length && this.$children) {
      this.store.startTimeAgoLoops.call(this, Vue);
    }
  },

  beforeDestroyed() {
    eventHub.$off('refreshPipelines');
  },

  methods: {
    fetchPipelines() {
      this.isLoading = true;
      return this.service.getPipelines()
        .then(response => response.json())
        .then((json) => {
          // depending of the endpoint the response can either bring a `pipelines` key or not.
          const pipelines = json.pipelines || json;
          this.store.storePipelines(pipelines);
          this.isLoading = false;
        })
        .catch(() => {
          this.hasError = true;
          this.isLoading = false;
        });
    },
  },

  template: `
    <div class="content-list pipelines">
      <div class="realtime-loading" v-if="isLoading">
        <i class="fa fa-spinner fa-spin"></i>
      </div>

      <empty-state
        v-if="shouldRenderEmptyState"
        :help-page-path="helpPagePath" />

      <error-state v-if="shouldRenderErrorState" />

      <div class="table-holder"
        v-if="!isLoading && state.pipelines.length > 0">
        <pipelines-table-component
          :pipelines="state.pipelines"
          :service="service" />
      </div>
    </div>
  `,
});
