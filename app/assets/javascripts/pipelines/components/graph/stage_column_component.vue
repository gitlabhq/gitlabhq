<script>
import _ from 'underscore';
import JobItem from './job_item.vue';
import JobGroupDropdown from './job_group_dropdown.vue';

export default {
  components: {
    JobItem,
    JobGroupDropdown,
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
  },
  methods: {
    groupId(group) {
      return `ci-badge-${_.escape(group.name)}`;
    },
    buildConnnectorClass(index) {
      return index === 0 && !this.isFirstColumn ? 'left-connector' : '';
    },
    pipelineActionRequestComplete() {
      this.$emit('refreshPipelineGraph');
    },
  },
};
</script>
<template>
  <li :class="stageConnectorClass" class="stage-column">
    <div class="stage-name">{{ title }}</div>
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
