<script>
  import ciStatus from '~/vue_shared/components/ci_icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    components: {
      ciStatus,
    },
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
        v-tooltip
        class="linked-pipeline-content"
        :href="pipelinePath"
        :title="tooltipText"
        data-container="body"
      >
        <span class="linked-pipeline-status ci-status-text">
          <ci-status :status="pipelineStatus" />
        </span>
        <span class="linked-pipeline-project-name">{{ projectName }}</span>
        <span class="project-name-pipeline-id-separator">&#8226;</span>
        <span class="linked-pipeline-id">#{{ pipelineId }}</span>
      </a>
    </div>
  </li>
</template>
