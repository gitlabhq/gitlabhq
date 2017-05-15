<script>
export default {
  props: {
    pipelineId: {
      type: String,
      required: true,
    },
    pipelinePath: {
      type: String,
      required: true,
    },
    pipelineStatus: {
      type: String,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
  },
};

</script>

<template>
  <li class="build">
    <a :href="pipelinePath" class="build-content">
      <span class="linked-pipeline-status"> {{ pipelineStatus }} </span>
      <span class="linked-pipeline-project-name"> {{ projectName }}</span>
      <span class="linked-pipeline-id"> #{{ pipelineId }}</span>
    </a>
  </li>
</template>
