<script>
import RunnerShow from '../components/runner_show.vue';

export default {
  name: 'GroupRunnerShowApp',
  components: {
    RunnerShow,
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
  <runner-show
    :runner-id="runnerId"
    :runners-path="runnersPath"
    :edit-path="editPath"
    :show-access-help="true"
  />
</template>
