<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import { DRAW_FAILURE, DEFAULT } from '../../constants';
import LinksLayer from '../graph_shared/links_layer.vue';
import JobPill from './job_pill.vue';
import StagePill from './stage_pill.vue';

export default {
  components: {
    GlAlert,
    JobPill,
    LinksLayer,
    StagePill,
  },
  CONTAINER_REF: 'PIPELINE_GRAPH_CONTAINER_REF',
  BASE_CONTAINER_ID: 'pipeline-graph-container',
  PIPELINE_ID: 0,
  STROKE_WIDTH: 2,
  errorTexts: {
    [DRAW_FAILURE]: __('Could not draw the lines for job relationships'),
    [DEFAULT]: __('An unknown error occurred.'),
  },
  props: {
    pipelineData: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      failureType: null,
      highlightedJob: null,
      highlightedJobs: [],
      measurements: {
        height: 0,
        width: 0,
      },
    };
  },
  computed: {
    containerId() {
      return `${this.$options.BASE_CONTAINER_ID}-${this.$options.PIPELINE_ID}`;
    },
    failure() {
      switch (this.failureType) {
        case DRAW_FAILURE:
          return {
            text: this.$options.errorTexts[DRAW_FAILURE],
            variant: 'danger',
            dismissible: true,
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT],
            variant: 'danger',
            dismissible: true,
          };
      }
    },
    hasError() {
      return this.failureType;
    },
    hasHighlightedJob() {
      return Boolean(this.highlightedJob);
    },
    pipelineStages() {
      return this.pipelineData?.stages || [];
    },
  },
  watch: {
    pipelineData: {
      immediate: true,
      handler() {
        this.$nextTick(() => {
          this.computeGraphDimensions();
        });
      },
    },
  },
  methods: {
    computeGraphDimensions() {
      this.measurements = {
        width: this.$refs[this.$options.CONTAINER_REF].scrollWidth,
        height: this.$refs[this.$options.CONTAINER_REF].scrollHeight,
      };
    },
    getStageBackgroundClasses(index) {
      const { length } = this.pipelineStages;
      // It's possible for a graph to have only one stage, in which
      // case we concatenate both the left and right rounding classes
      if (length === 1) {
        return 'gl-rounded-bottom-left-6 gl-rounded-top-left-6 gl-rounded-bottom-right-6 gl-rounded-top-right-6';
      }

      if (index === 0) {
        return 'gl-rounded-bottom-left-6 gl-rounded-top-left-6';
      }

      if (index === length - 1) {
        return 'gl-rounded-bottom-right-6 gl-rounded-top-right-6';
      }

      return '';
    },
    isJobHighlighted(jobName) {
      return this.highlightedJobs.includes(jobName);
    },
    onError(error) {
      this.reportFailure(error.type);
    },
    removeHoveredJob() {
      this.highlightedJob = null;
    },
    reportFailure(errorType) {
      this.failureType = errorType;
    },
    resetFailure() {
      this.failureType = null;
    },
    setHoveredJob(jobName) {
      this.highlightedJob = jobName;
    },
    updateHighlightedJobs(jobs) {
      this.highlightedJobs = jobs;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="hasError"
      :variant="failure.variant"
      :dismissible="failure.dismissible"
      @dismiss="resetFailure"
    >
      {{ failure.text }}
    </gl-alert>
    <div :id="containerId" :ref="$options.CONTAINER_REF" data-testid="graph-container">
      <links-layer
        :pipeline-data="pipelineStages"
        :pipeline-id="$options.PIPELINE_ID"
        :container-id="containerId"
        :container-measurements="measurements"
        :highlighted-job="highlightedJob"
        @highlightedJobsChange="updateHighlightedJobs"
        @error="onError"
      >
        <div
          v-for="(stage, index) in pipelineStages"
          :key="`${stage.name}-${index}`"
          class="gl-flex-direction-column"
        >
          <div
            class="gl-display-flex gl-align-items-center gl-bg-white gl-w-full gl-px-8 gl-py-4 gl-mb-5"
            :class="getStageBackgroundClasses(index)"
            data-testid="stage-background"
          >
            <stage-pill :stage-name="stage.name" :is-empty="stage.groups.length === 0" />
          </div>
          <div
            class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-w-full gl-px-8"
          >
            <job-pill
              v-for="group in stage.groups"
              :key="group.name"
              :job-name="group.name"
              :pipeline-id="$options.PIPELINE_ID"
              :is-highlighted="hasHighlightedJob && isJobHighlighted(group.name)"
              :is-faded-out="hasHighlightedJob && !isJobHighlighted(group.name)"
              @on-mouse-enter="setHoveredJob"
              @on-mouse-leave="removeHoveredJob"
            />
          </div>
        </div>
      </links-layer>
    </div>
  </div>
</template>
