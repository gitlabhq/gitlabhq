<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import PipelinesService from '~/pipelines/services/pipelines_service';
import PipelineStore from '~/pipelines/stores/pipelines_store';
import pipelinesMixin from '~/pipelines/mixins/pipelines';
import eventHub from '~/pipelines/event_hub';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { getParameterByName } from '~/lib/utils/common_utils';
import CIPaginationMixin from '~/vue_shared/mixins/ci_pagination_api_mixin';

export default {
  components: {
    TablePagination,
    GlButton,
    GlLoadingIcon,
  },
  mixins: [pipelinesMixin, CIPaginationMixin],
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    autoDevopsHelpPath: {
      type: String,
      required: true,
    },
    errorStateSvgPath: {
      type: String,
      required: true,
    },
    viewType: {
      type: String,
      required: false,
      default: 'child',
    },
    canRunPipeline: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    mergeRequestId: {
      type: Number,
      required: false,
      default: 0,
    },
  },

  data() {
    const store = new PipelineStore();

    return {
      store,
      state: store.state,
      page: getParameterByName('page') || '1',
      requestData: {},
    };
  },

  computed: {
    shouldRenderTable() {
      return !this.isLoading && this.state.pipelines.length > 0 && !this.hasError;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    /**
     * The Run Pipeline button can only be rendered when:
     * - In MR view -  we use `canRunPipeline` for that purpose
     * - If the latest pipeline has the `detached_merge_request_pipeline` flag
     *
     * @returns {Boolean}
     */
    canRenderPipelineButton() {
      return this.canRunPipeline && this.latestPipelineDetachedFlag;
    },
    /**
     * Checks if either `detached_merge_request_pipeline` or
     * `merge_request_pipeline` are tru in the first
     * object in the pipelines array.
     *
     * @returns {Boolean}
     */
    latestPipelineDetachedFlag() {
      const latest = this.state.pipelines[0];
      return (
        latest &&
        latest.flags &&
        (latest.flags.detached_merge_request_pipeline || latest.flags.merge_request_pipeline)
      );
    },
    /**
     * When we are on Desktop and the button is visible
     * we need to add a negative margin to the table
     * to make it inline with the button
     *
     * @returns {Boolean}
     */
    shouldAddNegativeMargin() {
      return this.canRenderPipelineButton && bp.isDesktop();
    },
  },
  created() {
    this.service = new PipelinesService(this.endpoint);
    this.requestData = { page: this.page };
  },
  methods: {
    successCallback(resp) {
      // depending of the endpoint the response can either bring a `pipelines` key or not.
      const pipelines = resp.data.pipelines || resp.data;

      this.store.storePagination(resp.headers);
      this.setCommonData(pipelines);

      const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
        detail: {
          pipelines: resp.data,
        },
      });

      // notifiy to update the count in tabs
      if (this.$el.parentElement) {
        this.$el.parentElement.dispatchEvent(updatePipelinesEvent);
      }
    },
    /**
     * When the user clicks on the Run Pipeline button
     * we need to make a post request and
     * to update the table content once the request is finished.
     *
     * We are emitting an event through the eventHub using the old pattern
     * to make use of the code in mixins/pipelines.js that handles all the
     * table events
     *
     */
    onClickRunPipeline() {
      eventHub.$emit('runMergeRequestPipeline', {
        projectId: this.projectId,
        mergeRequestId: this.mergeRequestId,
      });
    },
  },
};
</script>
<template>
  <div class="content-list pipelines">
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading Pipelines')"
      :size="3"
      class="prepend-top-20"
    />

    <svg-blank-state
      v-else-if="shouldRenderErrorState"
      :svg-path="errorStateSvgPath"
      :message="
        s__(`Pipelines|There was an error fetching the pipelines.
      Try again in a few moments or contact your support team.`)
      "
    />

    <div v-else-if="shouldRenderTable" class="table-holder">
      <div v-if="canRenderPipelineButton" class="nav justify-content-end">
        <gl-button
          v-if="canRenderPipelineButton"
          variant="success"
          class="js-run-mr-pipeline prepend-top-10 btn-wide-on-xs"
          :disabled="state.isRunningMergeRequestPipeline"
          @click="onClickRunPipeline"
        >
          <gl-loading-icon v-if="state.isRunningMergeRequestPipeline" inline />
          {{ s__('Pipelines|Run Pipeline') }}
        </gl-button>
      </div>

      <pipelines-table-component
        :pipelines="state.pipelines"
        :update-graph-dropdown="updateGraphDropdown"
        :auto-devops-help-path="autoDevopsHelpPath"
        :view-type="viewType"
        :class="{ 'negative-margin-top': shouldAddNegativeMargin }"
      />
    </div>

    <table-pagination
      v-if="shouldRenderPagination"
      :change="onChangePage"
      :page-info="state.pageInfo"
    />
  </div>
</template>
