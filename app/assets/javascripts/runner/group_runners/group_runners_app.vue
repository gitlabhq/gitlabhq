<script>
import RunnerManualSetupHelp from '../components/runner_manual_setup_help.vue';
import RunnerTypeHelp from '../components/runner_type_help.vue';
import { GROUP_TYPE } from '../constants';

export default {
  components: {
    RunnerManualSetupHelp,
    RunnerTypeHelp,
  },
  props: {
    registrationToken: {
      type: String,
      required: true,
    },
  },
  GROUP_TYPE,
};
</script>

<template>
  <div>
    <div class="row">
      <div class="col-sm-6">
        <runner-type-help />
      </div>
      <div class="col-sm-6">
        <runner-manual-setup-help
          :registration-token="registrationToken"
          :type="$options.GROUP_TYPE"
        />
      </div>
    </div>
  </div>
</template>
