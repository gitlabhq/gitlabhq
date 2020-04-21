<script>
import { isEmpty, escape } from 'lodash';
import stageColumnMixin from '../../mixins/stage_column_mixin';
import JobItem from './job_item.vue';
import JobGroupDropdown from './job_group_dropdown.vue';
import ActionComponent from './action_component.vue';

export default {
  components: {
    JobItem,
    JobGroupDropdown,
    ActionComponent,
  },
  mixins: [stageColumnMixin],
  props: {
    title: {
      type: String,
      required: true,
    },
    groups: {
      type: Array,
      required: true,
    },
    isFirstColumn: {
      type: Boolean,
      required: false,
      default: false,
    },
    stageConnectorClass: {
      type: String,
      required: false,
      default: '',
    },
    action: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    hasAction() {
      return !isEmpty(this.action);
    },
  },
  methods: {
    groupId(group) {
      return `ci-badge-${escape(group.name)}`;
    },
    pipelineActionRequestComplete() {
      this.$emit('refreshPipelineGraph');
    },
  },
};
</script>
<template>
  <li :class="stageConnectorClass" class="stage-column">
    <div class="stage-name position-relative">
      {{ title }}
      <action-component
        v-if="hasAction"
        :action-icon="action.icon"
        :tooltip-text="action.title"
        :link="action.path"
        class="js-stage-action stage-action position-absolute position-top-0 rounded"
        @pipelineActionRequestComplete="pipelineActionRequestComplete"
      />
    </div>

    <div class="builds-container">
      <ul>
        <li
          v-for="(group, index) in groups"
          :id="groupId(group)"
          :key="group.id"
          :class="buildConnnectorClass(index)"
          class="build"
        >
          <div class="curve"></div>

          <job-item
            v-if="group.size === 1"
            :job="group.jobs[0]"
            css-class-job-name="build-content"
            @pipelineActionRequestComplete="pipelineActionRequestComplete"
          />

          <job-group-dropdown
            v-if="group.size > 1"
            :group="group"
            @pipelineActionRequestComplete="pipelineActionRequestComplete"
          />
        </li>
      </ul>
    </div>
  </li>
</template>
