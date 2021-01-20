<script>
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import LinkedPipeline from './linked_pipeline.vue';
import { LOAD_FAILURE } from '../../constants';
import { UPSTREAM } from './constants';
import { unwrapPipelineData, toggleQueryPollingByVisibility, reportToSentry } from './utils';

export default {
  components: {
    LinkedPipeline,
    PipelineGraph: () => import('./graph_component.vue'),
  },
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    linkedPipelines: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentPipeline: null,
      loadingPipelineId: null,
      pipelineExpanded: false,
    };
  },
  titleClasses: [
    'gl-font-weight-bold',
    'gl-pipeline-job-width',
    'gl-text-truncate',
    'gl-line-height-36',
    'gl-pl-3',
    'gl-mb-5',
  ],
  computed: {
    columnClass() {
      const positionValues = {
        right: 'gl-ml-6',
        left: 'gl-mr-6',
      };
      return `graph-position-${this.graphPosition} ${positionValues[this.graphPosition]}`;
    },
    graphPosition() {
      return this.isUpstream ? 'left' : 'right';
    },
    isUpstream() {
      return this.type === UPSTREAM;
    },
    computedTitleClasses() {
      const positionalClasses = this.isUpstream
        ? ['gl-w-full', 'gl-text-right', 'gl-linked-pipeline-padding']
        : [];

      return [...this.$options.titleClasses, ...positionalClasses];
    },
  },
  methods: {
    getPipelineData(pipeline) {
      const projectPath = pipeline.project.fullPath;

      this.$apollo.addSmartQuery('currentPipeline', {
        query: getPipelineDetails,
        pollInterval: 10000,
        variables() {
          return {
            projectPath,
            iid: pipeline.iid,
          };
        },
        update(data) {
          return unwrapPipelineData(projectPath, data);
        },
        result() {
          this.loadingPipelineId = null;
        },
        error(err, _vm, _key, type) {
          this.$emit('error', LOAD_FAILURE);

          reportToSentry(
            'linked_pipelines_column',
            `error type: ${LOAD_FAILURE}, error: ${err}, apollo error type: ${type}`,
          );
        },
      });

      toggleQueryPollingByVisibility(this.$apollo.queries.currentPipeline);
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
        this.pipelineExpanded = false;
        this.currentPipeline = null;
        return;
      }

      /* Set the loading id */
      this.loadingPipelineId = pipeline.id;

      /*
        Expand the pipeline.
        If this was not a toggle close action, and
        it was already showing a different pipeline, then
        this will be a no-op, but that doesn't matter.
      */
      this.pipelineExpanded = true;

      this.getPipelineData(pipeline);
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
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <div :class="columnClass" class="linked-pipelines-column">
      <div data-testid="linked-column-title" class="stage-name" :class="computedTitleClasses">
        {{ columnTitle }}
      </div>
      <ul class="gl-pl-0">
        <li
          v-for="pipeline in linkedPipelines"
          :key="pipeline.id"
          class="gl-display-flex gl-mb-4"
          :class="{ 'gl-flex-direction-row-reverse': isUpstream }"
        >
          <linked-pipeline
            class="gl-display-inline-block"
            :is-loading="isLoadingPipeline(pipeline.id)"
            :pipeline="pipeline"
            :column-title="columnTitle"
            :type="type"
            :expanded="isExpanded(pipeline.id)"
            @downstreamHovered="onDownstreamHovered"
            @pipelineClicked="onPipelineClick(pipeline)"
            @pipelineExpandToggle="onPipelineExpandToggle"
          />
          <div v-if="isExpanded(pipeline.id)" class="gl-display-inline-block">
            <pipeline-graph
              v-if="currentPipeline"
              :type="type"
              class="d-inline-block gl-mt-n2"
              :pipeline="currentPipeline"
              :is-linked-pipeline="true"
            />
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>
