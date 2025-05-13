<script>
import RunnerDetailsTabs from '../components/runner_details_tabs.vue';

export default {
  name: 'AdminRunnerShowApp',
  components: {
    RunnerDetailsTabs,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
      type: String,
      required: true,
    },
    editPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <runner-details-tabs :runner-id="runnerId" :runners-path="runnersPath" :edit-path="editPath" />
</template>
