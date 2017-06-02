<script>
import ciStatus from '../../../vue_shared/components/ci_icon.vue';

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
  components: {
    ciStatus,
  },
};

</script>

<template>
  <li class="linked-pipeline build">
    <div class="curve"></div>
    <div>
      <a :href="pipelinePath" class="linked-pipeline-content">
        <span class="linked-pipeline-status ci-status-text">
          <ci-status :status="pipelineStatus"/>
        </span>
        <span class="linked-pipeline-project-name"> {{ projectName }}</span>
        <span class="linked-pipeline-id"> &#8226; #{{ pipelineId }}</span>
      </a>
    </div>
  </li>
</template>
