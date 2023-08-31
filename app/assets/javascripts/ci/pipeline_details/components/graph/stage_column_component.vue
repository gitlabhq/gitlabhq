<script>
import { escape, isEmpty } from 'lodash';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { reportToSentry } from '../../utils';
import MainGraphWrapper from '../graph_shared/main_graph_wrapper.vue';
import ActionComponent from '../jobs_shared/action_component.vue';
import JobGroupDropdown from './job_group_dropdown.vue';
import JobItem from './job_item.vue';

export default {
  components: {
    ActionComponent,
    JobGroupDropdown,
    JobItem,
    MainGraphWrapper,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    groups: {
      type: Array,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: true,
    },
    action: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    highlightedJobs: {
      type: Array,
      required: false,
      default: () => [],
    },
    isStageView: {
      type: Boolean,
      required: false,
      default: false,
    },
    jobHovered: {
      type: String,
      required: false,
      default: '',
    },
    pipelineExpanded: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    skipRetryModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    sourceJobHovered: {
      type: String,
      required: false,
      default: '',
    },
    userPermissions: {
      type: Object,
      required: true,
    },
  },
  jobClasses: [
    'gl-p-3',
    'gl-border-gray-100',
    'gl-border-solid',
    'gl-border-1',
    'gl-bg-white',
    'gl-rounded-7',
    'gl-hover-bg-gray-50',
    'gl-focus-bg-gray-50',
    'gl-hover-text-gray-900',
    'gl-focus-text-gray-900',
    'gl-hover-border-gray-200',
    'gl-focus-border-gray-200',
  ],
  titleClasses: [
    'gl-font-weight-bold',
    'gl-pipeline-job-width',
    'gl-text-truncate',
    'gl-line-height-36',
    'gl-pl-3',
  ],
  computed: {
    canUpdatePipeline() {
      return this.userPermissions.updatePipeline;
    },
    columnSpacingClass() {
      return this.isStageView ? 'gl-px-6' : 'gl-px-9';
    },
    hasAction() {
      return !isEmpty(this.action);
    },
    showStageName() {
      return !this.isStageView;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('stage_column_component', `error: ${err}, info: ${info}`);
  },
  mounted() {
    this.$emit('updateMeasurements');
  },
  methods: {
    getGroupId(group) {
      return group.name;
    },
    groupId(group) {
      return `ci-badge-${escape(group.name)}`;
    },
    isFadedOut(jobName) {
      return this.highlightedJobs.length > 1 && !this.highlightedJobs.includes(jobName);
    },
    isParallel(group) {
      return group.size > 1 && group.jobs.length > 1;
    },
    singleJobExists(group) {
      const firstJobDefined = Boolean(group.jobs?.[0]);

      if (!firstJobDefined) {
        reportToSentry('stage_column_component', 'undefined_job_hunt');
      }

      return group.size === 1 && firstJobDefined;
    },
  },
};
</script>
<template>
  <main-graph-wrapper :class="columnSpacingClass" data-testid="stage-column">
    <template #stages>
      <div
        data-testid="stage-column-title"
        class="gl-display-flex gl-justify-content-space-between gl-relative"
        :class="$options.titleClasses"
      >
        <span :title="name" class="gl-text-truncate gl-pr-3 gl-w-85p">
          {{ name }}
        </span>
        <action-component
          v-if="hasAction && canUpdatePipeline"
          :action-icon="action.icon"
          :tooltip-text="action.title"
          :link="action.path"
          class="js-stage-action"
          @pipelineActionRequestComplete="$emit('refreshPipelineGraph')"
        />
      </div>
    </template>
    <template #jobs>
      <div
        v-for="group in groups"
        :id="groupId(group)"
        :key="getGroupId(group)"
        data-testid="stage-column-group"
        class="gl-relative gl-mb-3 gl-white-space-normal gl-pipeline-job-width"
        @mouseenter="$emit('jobHover', group.name)"
        @mouseleave="$emit('jobHover', '')"
      >
        <job-item
          v-if="singleJobExists(group)"
          :job="group.jobs[0]"
          :job-hovered="jobHovered"
          :skip-retry-modal="skipRetryModal"
          :source-job-hovered="sourceJobHovered"
          :pipeline-expanded="pipelineExpanded"
          :pipeline-id="pipelineId"
          :stage-name="showStageName ? group.stageName : ''"
          :css-class-job-name="$options.jobClasses"
          :class="[
            { 'gl-opacity-3': isFadedOut(group.name) },
            'gl-transition-duration-slow gl-transition-timing-function-ease',
          ]"
          @pipelineActionRequestComplete="$emit('refreshPipelineGraph')"
          @setSkipRetryModal="$emit('setSkipRetryModal')"
        />
        <div v-else-if="isParallel(group)" :class="{ 'gl-opacity-3': isFadedOut(group.name) }">
          <job-group-dropdown
            :group="group"
            :stage-name="showStageName ? group.stageName : ''"
            :pipeline-id="pipelineId"
            :css-class-job-name="$options.jobClasses"
          />
        </div>
      </div>
    </template>
  </main-graph-wrapper>
</template>
