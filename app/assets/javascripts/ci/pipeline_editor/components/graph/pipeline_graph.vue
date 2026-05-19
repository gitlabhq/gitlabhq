<script>
import { GlAlert } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import { DRAW_FAILURE, DEFAULT } from '~/ci/pipeline_details/constants';
import LinksLayer from '~/ci/common/private/job_links_layer.vue';
import JobRow from './job_row.vue';

export default {
  components: {
    GlAlert,
    JobRow,
    LinksLayer,
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
  cardClasses:
    'gl-shadow-inner-1-black-300 gl-mr-8 gl-min-w-[280px] gl-flex-col gl-items-center gl-self-stretch gl-rounded-lg gl-border-solid gl-border-default gl-bg-default gl-py-3',
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
    numberOfJobsSubheader(groups) {
      const jobsLength = groups.length;

      return sprintf(n__('%{jobsLength} job', '%{jobsLength} jobs', jobsLength), {
        jobsLength,
      });
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
        @highlighted-jobs-change="updateHighlightedJobs"
        @error="onError"
      >
        <div class="gl-relative gl-flex gl-p-8">
          <div
            v-for="(stage, index) in pipelineStages"
            :key="`${stage.name}-${index}`"
            :class="$options.cardClasses"
          >
            <!--Card header and separator-->
            <div class="gl-flex gl-items-center gl-justify-center gl-px-5 gl-pb-3">
              <div class="gl-ml-5 gl-flex gl-grow-2 gl-flex-col" data-testid="card-header">
                <strong>{{ stage.name }}</strong>
                <p class="gl-m-0 gl-text-subtle">{{ numberOfJobsSubheader(stage.groups) }}</p>
              </div>
            </div>
            <div class="gl-border-b gl-border-solid gl-border-default"></div>
            <div class="gl-flex gl-flex-col gl-pt-3">
              <job-row
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
        </div>
      </links-layer>
    </div>
  </div>
</template>
