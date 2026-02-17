<script>
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { reportToSentry } from '~/ci/utils';
import { LOAD_FAILURE } from '../../constants';
import { ONE_COL_WIDTH, UPSTREAM, LAYER_VIEW, STAGE_VIEW } from '../constants';
import {
  calculatePipelineLayersInfo,
  getQueryHeaders,
  serializeLoadErrors,
  toggleQueryPollingByVisibility,
  unwrapPipelineData,
  validateConfigPaths,
} from '../utils';
import LinkedPipeline from './linked_pipeline.vue';

export default {
  name: 'LinkedPipelinesColumn',
  components: {
    LinkedPipeline,
    PipelineGraph: () => import(/* webpackChunkName: 'pipeline_graph' */ './graph_component.vue'),
  },
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    configPaths: {
      type: Object,
      required: true,
      validator: validateConfigPaths,
    },
    linkedPipelines: {
      type: Array,
      required: true,
    },
    showLinks: {
      type: Boolean,
      required: true,
    },
    skipRetryModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    type: {
      type: String,
      required: true,
    },
    viewType: {
      type: String,
      required: true,
    },
    userPermissions: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      currentPipeline: null,
      loadingPipelineId: null,
      pipelineLayers: {},
      expandedPipeline: null,
    };
  },
  apollo: {
    currentPipeline: {
      query: getPipelineDetails,
      pollInterval: 10000,
      context() {
        return getQueryHeaders(this.configPaths.graphqlResourceEtag);
      },
      variables() {
        return this.pipelineVariables;
      },
      skip() {
        return !this.pipelineVariables.iid || !this.pipelineVariables.projectPath;
      },
      update(data) {
        /*
          This check prevents the pipeline from being overwritten
          when a poll times out and the data returned is empty.
          This can be removed once the timeout behavior is updated.
          See: https://gitlab.com/gitlab-org/gitlab/-/issues/323213.
        */

        if (!data?.project?.pipeline) {
          return this.currentPipeline;
        }

        const incomingPipelineId = getIdFromGraphQLId(data.project.pipeline.id);

        if (incomingPipelineId !== this.expandedPipeline?.id) {
          return this.currentPipeline;
        }

        return unwrapPipelineData(
          this.pipelineVariables.projectPath,
          JSON.parse(JSON.stringify(data)),
        );
      },
      result() {
        this.loadingPipelineId = null;
        this.$emit('scrollContainer');
      },
      error(err) {
        this.$emit('error', { type: LOAD_FAILURE, skipSentry: true });

        reportToSentry(
          this.$options.name,
          `error type: ${LOAD_FAILURE}, error: ${serializeLoadErrors(err)}`,
        );
      },
    },
  },
  computed: {
    columnClass() {
      const positionValues = {
        right: 'gl-mx-5',
        left: 'gl-mx-4 gl-basis-full',
      };

      return `graph-position-${this.graphPosition} ${positionValues[this.graphPosition]}`;
    },
    computedTitleClasses() {
      const positionalClasses = this.isUpstream ? ['gl-w-full', 'gl-linked-pipeline-padding'] : [];

      return [...this.$options.titleClasses, ...positionalClasses];
    },
    graphPosition() {
      return this.isUpstream ? 'left' : 'right';
    },
    graphViewType() {
      return this.currentPipeline?.usesNeeds ? this.viewType : STAGE_VIEW;
    },
    isUpstream() {
      return this.type === UPSTREAM;
    },
    minWidth() {
      return this.isUpstream ? 0 : this.$options.minWidth;
    },
    pipelineVariables() {
      return {
        projectPath: this.expandedPipeline?.project?.fullPath,
        iid: this.expandedPipeline?.iid,
      };
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.currentPipeline);
  },
  titleClasses: ['gl-font-bold', 'gl-pipeline-job-width', 'gl-truncate', 'gl-leading-36'],
  minWidth: `${ONE_COL_WIDTH}px`,
  methods: {
    getPipelineLayers(id) {
      if (this.viewType === LAYER_VIEW && !this.pipelineLayers[id]) {
        this.pipelineLayers[id] = calculatePipelineLayersInfo(
          this.currentPipeline,
          this.$options.name,
          this.configPaths.metricsPath,
        );
      }

      return this.pipelineLayers[id];
    },
    isExpanded(id) {
      return Boolean(this.currentPipeline?.id && id === this.currentPipeline.id);
    },
    isLoadingPipeline(id) {
      return this.loadingPipelineId === id;
    },
    onPipelineClick(pipeline) {
      /* If the clicked pipeline has been expanded already, close it, clear, exit */
      if (this.currentPipeline?.id === pipeline.id) {
        this.expandedPipeline = null;
        this.currentPipeline = null;
        return;
      }

      /* Expand the pipeline - Apollo will automatically fetch when expandedPipeline changes */
      this.expandedPipeline = pipeline;
      this.loadingPipelineId = pipeline.id;
    },
    onDownstreamHovered(jobName) {
      this.$emit('downstreamHovered', jobName);
    },
    onPipelineExpandToggle(jobName, expanded) {
      // Highlighting only applies to downstream pipelines
      if (this.isUpstream) {
        return;
      }

      this.$emit('pipelineExpandToggle', jobName, expanded);
    },
    showContainer(id) {
      return this.isExpanded(id) || this.isLoadingPipeline(id);
    },
    getPipelinePermissions(id) {
      return this.userPermissions[id] || {};
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-w-full @sm/panel:gl-w-auto">
    <div :class="columnClass" class="linked-pipelines-column">
      <div data-testid="linked-column-title" :class="computedTitleClasses">
        {{ columnTitle }}
      </div>
      <ul class="gl-pl-0">
        <li
          v-for="pipeline in linkedPipelines"
          :key="pipeline.id"
          class="gl-mb-6 gl-flex gl-flex-wrap @sm/panel:gl-flex-nowrap"
        >
          <linked-pipeline
            :is-loading="isLoadingPipeline(pipeline.id)"
            :pipeline="pipeline"
            :type="type"
            :expanded="isExpanded(pipeline.id)"
            :user-permissions="getPipelinePermissions(pipeline.id)"
            @downstreamHovered="onDownstreamHovered"
            @pipelineClicked="onPipelineClick(pipeline)"
            @pipelineExpandToggle="onPipelineExpandToggle"
            @refreshPipelineGraph="$emit('refreshPipelineGraph')"
          />
          <div
            v-if="showContainer(pipeline.id)"
            :style="{ minWidth }"
            class="pipeline-show-container gl-inline-block"
          >
            <pipeline-graph
              v-if="isExpanded(pipeline.id)"
              :type="type"
              class="gl-inline-block"
              :config-paths="configPaths"
              :pipeline="currentPipeline"
              :user-permissions="userPermissions"
              :computed-pipeline-info="getPipelineLayers(pipeline.id)"
              :show-links="showLinks"
              :skip-retry-modal="skipRetryModal"
              :is-linked-pipeline="true"
              :view-type="graphViewType"
              @setSkipRetryModal="$emit('setSkipRetryModal')"
            />
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>
