<script>
import LinkedGraphWrapper from '../graph_shared/linked_graph_wrapper.vue';
import LinkedPipelinesColumn from './linked_pipelines_column.vue';
import StageColumnComponent from './stage_column_component.vue';
import { DOWNSTREAM, MAIN, UPSTREAM } from './constants';
import { reportToSentry } from './utils';

export default {
  name: 'PipelineGraph',
  components: {
    LinkedGraphWrapper,
    LinkedPipelinesColumn,
    StageColumnComponent,
  },
  props: {
    isLinkedPipeline: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: false,
      default: MAIN,
    },
  },
  pipelineTypeConstants: {
    DOWNSTREAM,
    UPSTREAM,
  },
  data() {
    return {
      hoveredJobName: '',
      pipelineExpanded: {
        jobName: '',
        expanded: false,
      },
    };
  },
  computed: {
    downstreamPipelines() {
      return this.hasDownstreamPipelines ? this.pipeline.downstream : [];
    },
    graph() {
      return this.pipeline.stages;
    },
    hasDownstreamPipelines() {
      return Boolean(this.pipeline?.downstream?.length > 0);
    },
    hasUpstreamPipelines() {
      return Boolean(this.pipeline?.upstream?.length > 0);
    },
    // The two show checks prevent upstream / downstream from showing redundant linked columns
    showDownstreamPipelines() {
      return (
        this.hasDownstreamPipelines && this.type !== this.$options.pipelineTypeConstants.UPSTREAM
      );
    },
    showUpstreamPipelines() {
      return (
        this.hasUpstreamPipelines && this.type !== this.$options.pipelineTypeConstants.DOWNSTREAM
      );
    },
    upstreamPipelines() {
      return this.hasUpstreamPipelines ? this.pipeline.upstream : [];
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
  methods: {
    setJob(jobName) {
      this.hoveredJobName = jobName;
    },
    togglePipelineExpanded(jobName, expanded) {
      this.pipelineExpanded = {
        expanded,
        jobName: expanded ? jobName : '',
      };
    },
  },
};
</script>
<template>
  <div class="js-pipeline-graph">
    <div
      class="gl-pipeline-min-h gl-display-flex gl-position-relative gl-overflow-auto gl-bg-gray-10 gl-white-space-nowrap"
      :class="{ 'gl-py-5': !isLinkedPipeline }"
    >
      <linked-graph-wrapper>
        <template #upstream>
          <linked-pipelines-column
            v-if="showUpstreamPipelines"
            :linked-pipelines="upstreamPipelines"
            :column-title="__('Upstream')"
            :type="$options.pipelineTypeConstants.UPSTREAM"
            @error="emit('error', errorType)"
          />
        </template>
        <template #main>
          <stage-column-component
            v-for="stage in graph"
            :key="stage.name"
            :title="stage.name"
            :groups="stage.groups"
            :action="stage.status.action"
            :job-hovered="hoveredJobName"
            :pipeline-expanded="pipelineExpanded"
            @refreshPipelineGraph="$emit('refreshPipelineGraph')"
          />
        </template>
        <template #downstream>
          <linked-pipelines-column
            v-if="showDownstreamPipelines"
            :linked-pipelines="downstreamPipelines"
            :column-title="__('Downstream')"
            :type="$options.pipelineTypeConstants.DOWNSTREAM"
            @downstreamHovered="setJob"
            @pipelineExpandToggle="togglePipelineExpanded"
            @error="emit('error', errorType)"
          />
        </template>
      </linked-graph-wrapper>
    </div>
  </div>
</template>
