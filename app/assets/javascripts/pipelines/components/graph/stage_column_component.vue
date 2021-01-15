<script>
import { capitalize, escape, isEmpty } from 'lodash';
import MainGraphWrapper from '../graph_shared/main_graph_wrapper.vue';
import JobItem from './job_item.vue';
import JobGroupDropdown from './job_group_dropdown.vue';
import ActionComponent from './action_component.vue';
import { GRAPHQL } from './constants';
import { accessValue } from './accessors';
import { reportToSentry } from './utils';

export default {
  components: {
    ActionComponent,
    JobGroupDropdown,
    JobItem,
    MainGraphWrapper,
  },
  props: {
    groups: {
      type: Array,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: true,
    },
    title: {
      type: String,
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
  },
  titleClasses: [
    'gl-font-weight-bold',
    'gl-pipeline-job-width',
    'gl-text-truncate',
    'gl-line-height-36',
    'gl-pl-3',
  ],
  computed: {
    formattedTitle() {
      return capitalize(escape(this.title));
    },
    hasAction() {
      return !isEmpty(this.action);
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('stage_column_component', `error: ${err}, info: ${info}`);
  },
  methods: {
    getGroupId(group) {
      return accessValue(GRAPHQL, 'groupId', group);
    },
    groupId(group) {
      return `ci-badge-${escape(group.name)}`;
    },
    isFadedOut(jobName) {
      return (
        this.jobHovered &&
        this.highlightedJobs.length > 1 &&
        !this.highlightedJobs.includes(jobName)
      );
    },
  },
};
</script>
<template>
  <main-graph-wrapper class="gl-px-6">
    <template #stages>
      <div
        data-testid="stage-column-title"
        class="gl-display-flex gl-justify-content-space-between gl-relative"
        :class="$options.titleClasses"
      >
        <div>{{ formattedTitle }}</div>
        <action-component
          v-if="hasAction"
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
          v-if="group.size === 1"
          :job="group.jobs[0]"
          :job-hovered="jobHovered"
          :pipeline-expanded="pipelineExpanded"
          :pipeline-id="pipelineId"
          css-class-job-name="gl-build-content"
          :class="{ 'gl-opacity-3': isFadedOut(group.name) }"
          @pipelineActionRequestComplete="$emit('refreshPipelineGraph')"
        />
        <job-group-dropdown
          v-else
          :group="group"
          :pipeline-id="pipelineId"
          :class="{ 'gl-opacity-3': isFadedOut(group.name) }"
        />
      </div>
    </template>
  </main-graph-wrapper>
</template>
