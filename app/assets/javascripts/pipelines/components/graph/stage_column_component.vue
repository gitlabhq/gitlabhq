<script>
import { capitalize, escape, isEmpty } from 'lodash';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { reportToSentry } from '../../utils';
import MainGraphWrapper from '../graph_shared/main_graph_wrapper.vue';
import ActionComponent from '../jobs_shared/action_component.vue';
import { accessValue } from './accessors';
import { GRAPHQL } from './constants';
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
    formattedTitle() {
      return capitalize(escape(this.name));
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
      return accessValue(GRAPHQL, 'groupId', group);
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
        <div>{{ formattedTitle }}</div>
        <action-component
          v-if="hasAction && canUpdatePipeline"
          :action-icon="action.icon"
          :tooltip-text="action.title"
          :link="action.path"
          class="js-stage-action stage-action rounded"
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
          :source-job-hovered="sourceJobHovered"
          :pipeline-expanded="pipelineExpanded"
          :pipeline-id="pipelineId"
          :stage-name="showStageName ? group.stageName : ''"
          css-class-job-name="gl-build-content"
          :class="[
            { 'gl-opacity-3': isFadedOut(group.name) },
            'gl-transition-duration-slow gl-transition-timing-function-ease',
          ]"
          @pipelineActionRequestComplete="$emit('refreshPipelineGraph')"
        />
        <div v-else-if="isParallel(group)" :class="{ 'gl-opacity-3': isFadedOut(group.name) }">
          <job-group-dropdown
            :group="group"
            :stage-name="showStageName ? group.stageName : ''"
            :pipeline-id="pipelineId"
          />
        </div>
      </div>
    </template>
  </main-graph-wrapper>
</template>
