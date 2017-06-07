<script>
import ciStatus from '../../../vue_shared/components/ci_icon.vue';
import tooltipMixin from '../../../vue_shared/mixins/tooltip';

export default {
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },
    pipelinePath: {
      type: String,
      required: true,
    },
    pipelineStatus: {
      type: Object,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
  },
  mixins: [
    tooltipMixin,
  ],
  components: {
    ciStatus,
  },
  computed: {
    tooltipText() {
      return `${this.projectName} - ${this.pipelineStatus.label}`;
    },
  },
};
</script>

<template>
  <li class="linked-pipeline build">
    <div class="curve"></div>
    <div>
      <a
        class="linked-pipeline-content"
        :href="pipelinePath"
        :title="tooltipText"
        ref="tooltip"
        data-toggle="tooltip"
        data-container="body">
        <span class="linked-pipeline-status ci-status-text">
          <ci-status :status="pipelineStatus"/>
        </span>
        <span class="linked-pipeline-project-name">{{ projectName }}</span>
        <span class="project-name-pipeline-id-separator">&#8226;</span>
        <span class="linked-pipeline-id">#{{ pipelineId }}</span>
      </a>
    </div>
  </li>
</template>
