<script>
import { isEmpty } from 'lodash';
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import JobPill from './job_pill.vue';
import StagePill from './stage_pill.vue';
import { generateLinksData } from './drawing_utils';
import { parseData } from '../parsing_utils';
import { DRAW_FAILURE, DEFAULT, INVALID_CI_CONFIG, EMPTY_PIPELINE_DATA } from '../../constants';
import { createJobsHash, generateJobNeedsDict } from '../../utils';
import { CI_CONFIG_STATUS_INVALID } from '~/pipeline_editor/constants';

export default {
  components: {
    GlAlert,
    JobPill,
    StagePill,
  },
  CONTAINER_REF: 'PIPELINE_GRAPH_CONTAINER_REF',
  CONTAINER_ID: 'pipeline-graph-container',
  STROKE_WIDTH: 2,
  errorTexts: {
    [DRAW_FAILURE]: __('Could not draw the lines for job relationships'),
    [DEFAULT]: __('An unknown error occurred.'),
  },
  warningTexts: {
    [EMPTY_PIPELINE_DATA]: __(
      'The visualization will appear in this tab when the CI/CD configuration file is populated with valid syntax.',
    ),
    [INVALID_CI_CONFIG]: __('Your CI configuration file is invalid.'),
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
      links: [],
      needsObject: null,
      height: 0,
      width: 0,
    };
  },
  computed: {
    pipelineStages() {
      return this.pipelineData?.stages || [];
    },
    isPipelineDataEmpty() {
      return !this.isInvalidCiConfig && isEmpty(this.pipelineStages);
    },
    isInvalidCiConfig() {
      return this.pipelineData?.status === CI_CONFIG_STATUS_INVALID;
    },
    showAlert() {
      return this.hasError || this.hasWarning;
    },
    hasError() {
      return this.failureType;
    },
    hasWarning() {
      return this.warning;
    },
    hasHighlightedJob() {
      return Boolean(this.highlightedJob);
    },
    alert() {
      if (this.hasError) {
        return this.failure;
      }

      return this.warning;
    },
    failure() {
      const text = this.$options.errorTexts[this.failureType] || this.$options.errorTexts[DEFAULT];

      return { text, variant: 'danger', dismissible: true };
    },
    warning() {
      if (this.isPipelineDataEmpty) {
        return {
          text: this.$options.warningTexts[EMPTY_PIPELINE_DATA],
          variant: 'tip',
          dismissible: false,
        };
      } else if (this.isInvalidCiConfig) {
        return {
          text: this.$options.warningTexts[INVALID_CI_CONFIG],
          variant: 'danger',
          dismissible: false,
        };
      }

      return null;
    },
    viewBox() {
      return [0, 0, this.width, this.height];
    },
    highlightedJobs() {
      // If you are hovering on a job, then the jobs we want to highlight are:
      // The job you are currently hovering + all of its needs.
      return this.hasHighlightedJob
        ? [this.highlightedJob, ...this.needsObject[this.highlightedJob]]
        : [];
    },
    highlightedLinks() {
      // If you are hovering on a job, then the links we want to highlight are:
      // All the links whose `source` and `target` are highlighted jobs.
      if (this.hasHighlightedJob) {
        const filteredLinks = this.links.filter((link) => {
          return (
            this.highlightedJobs.includes(link.source) && this.highlightedJobs.includes(link.target)
          );
        });

        return filteredLinks.map((link) => link.ref);
      }

      return [];
    },
  },
  mounted() {
    if (!this.isPipelineDataEmpty && !this.isInvalidCiConfig) {
      // This guarantee that all sub-elements are rendered
      // https://v3.vuejs.org/api/options-lifecycle-hooks.html#mounted
      this.$nextTick(() => {
        this.getGraphDimensions();
        this.prepareLinkData();
      });
    }
  },
  methods: {
    prepareLinkData() {
      try {
        const arrayOfJobs = this.pipelineStages.flatMap(({ groups }) => groups);
        const parsedData = parseData(arrayOfJobs);
        this.links = generateLinksData(parsedData, this.$options.CONTAINER_ID);
      } catch {
        this.reportFailure(DRAW_FAILURE);
      }
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
    highlightNeeds(uniqueJobId) {
      // The first time we hover, we create the object where
      // we store all the data to properly highlight the needs.
      if (!this.needsObject) {
        const jobs = createJobsHash(this.pipelineStages);
        this.needsObject = generateJobNeedsDict(jobs) ?? {};
      }

      this.highlightedJob = uniqueJobId;
    },
    removeHighlightNeeds() {
      this.highlightedJob = null;
    },
    getGraphDimensions() {
      this.width = `${this.$refs[this.$options.CONTAINER_REF].scrollWidth}`;
      this.height = `${this.$refs[this.$options.CONTAINER_REF].scrollHeight}`;
    },
    reportFailure(errorType) {
      this.failureType = errorType;
    },
    resetFailure() {
      this.failureType = null;
    },
    isJobHighlighted(jobName) {
      return this.highlightedJobs.includes(jobName);
    },
    isLinkHighlighted(linkRef) {
      return this.highlightedLinks.includes(linkRef);
    },
    getLinkClasses(link) {
      return [
        this.isLinkHighlighted(link.ref) ? 'gl-stroke-blue-400' : 'gl-stroke-gray-200',
        { 'gl-opacity-3': this.hasHighlightedJob && !this.isLinkHighlighted(link.ref) },
      ];
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="showAlert"
      :variant="alert.variant"
      :dismissible="alert.dismissible"
      @dismiss="alert.dismissible ? resetFailure : null"
    >
      {{ alert.text }}
    </gl-alert>
    <div
      v-if="!hasWarning"
      :id="$options.CONTAINER_ID"
      :ref="$options.CONTAINER_REF"
      class="gl-display-flex gl-bg-gray-50 gl-px-4 gl-overflow-auto gl-relative gl-py-7"
      data-testid="graph-container"
    >
      <svg :viewBox="viewBox" :width="width" :height="height" class="gl-absolute">
        <template>
          <path
            v-for="link in links"
            :key="link.path"
            :ref="link.ref"
            :d="link.path"
            class="gl-fill-transparent gl-transition-duration-slow gl-transition-timing-function-ease"
            :class="getLinkClasses(link)"
            :stroke-width="$options.STROKE_WIDTH"
          />
        </template>
      </svg>
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
            :is-highlighted="hasHighlightedJob && isJobHighlighted(group.name)"
            :is-faded-out="hasHighlightedJob && !isJobHighlighted(group.name)"
            @on-mouse-enter="highlightNeeds"
            @on-mouse-leave="removeHighlightNeeds"
          />
        </div>
      </div>
    </div>
  </div>
</template>
