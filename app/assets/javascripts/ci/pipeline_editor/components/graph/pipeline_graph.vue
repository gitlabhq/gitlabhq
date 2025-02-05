<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import { DRAW_FAILURE, DEFAULT } from '~/ci/pipeline_details/constants';
import LinksLayer from '~/ci/common/private/job_links_layer.vue';
import JobPill from './job_pill.vue';
import StageName from './stage_name.vue';

export default {
  components: {
    GlAlert,
    JobPill,
    LinksLayer,
    StageName,
  },
  CONTAINER_REF: 'PIPELINE_GRAPH_CONTAINER_REF',
  BASE_CONTAINER_ID: 'pipeline-graph-container',
  PIPELINE_ID: 0,
  STROKE_WIDTH: 2,
  errorTexts: {
    [DRAW_FAILURE]: __('Could not draw the lines for job relationships'),
    [DEFAULT]: __('An unknown error occurred.'),
  },
  // The combination of gl-w-full gl-min-w-full and gl-max-w-15 is necessary.
  // The max width and the width make sure the ellipsis to work and the min width
  // is for when there is less text than the stage column width (which the width 100% does not fix)
  jobWrapperClasses:
    'gl-flex gl-flex-col gl-items-stretch gl-w-full gl-px-8 gl-min-w-full gl-max-w-15',
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
    isFadedOut(jobName) {
      return this.highlightedJobs.length > 1 && !this.isJobHighlighted(jobName);
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
    <div
      :id="containerId"
      :ref="$options.CONTAINER_REF"
      class="gl-overflow-auto gl-bg-subtle"
      data-testid="graph-container"
    >
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
          class="gl-flex-col"
        >
          <div class="gl-mb-5 gl-flex gl-w-full gl-items-center gl-px-9 gl-py-4">
            <stage-name :stage-name="stage.name" />
          </div>
          <div :class="$options.jobWrapperClasses">
            <job-pill
              v-for="group in stage.groups"
              :key="group.name"
              :job-name="group.name"
              :pipeline-id="$options.PIPELINE_ID"
              :is-hovered="highlightedJob === group.name"
              :is-faded-out="isFadedOut(group.name)"
              @on-mouse-enter="setHoveredJob"
              @on-mouse-leave="removeHoveredJob"
            />
          </div>
        </div>
      </links-layer>
    </div>
  </div>
</template>
