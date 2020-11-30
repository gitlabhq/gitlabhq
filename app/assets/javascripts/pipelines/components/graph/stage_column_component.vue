<script>
import { capitalize, escape, isEmpty } from 'lodash';
import MainGraphWrapper from '../graph_shared/main_graph_wrapper.vue';
import JobItem from './job_item.vue';
import JobGroupDropdown from './job_group_dropdown.vue';
import ActionComponent from './action_component.vue';
import { GRAPHQL } from './constants';
import { accessValue } from './accessors';

export default {
  components: {
    ActionComponent,
    JobGroupDropdown,
    JobItem,
    MainGraphWrapper,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    groups: {
      type: Array,
      required: true,
    },
    action: {
      type: Object,
      required: false,
      default: () => ({}),
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
  methods: {
    getGroupId(group) {
      return accessValue(GRAPHQL, 'groupId', group);
    },
    groupId(group) {
      return `ci-badge-${escape(group.name)}`;
    },
  },
};
</script>
<template>
  <main-graph-wrapper>
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
      >
        <job-item
          v-if="group.size === 1"
          :job="group.jobs[0]"
          :job-hovered="jobHovered"
          :pipeline-expanded="pipelineExpanded"
          css-class-job-name="gl-build-content"
        />
        <job-group-dropdown v-else :group="group" />
      </div>
    </template>
  </main-graph-wrapper>
</template>
