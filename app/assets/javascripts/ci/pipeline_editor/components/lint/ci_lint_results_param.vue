<script>
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { sprintf, __ } from '~/locale';

export default {
  props: {
    stage: {
      type: String,
      required: true,
    },
    jobName: {
      type: String,
      required: true,
    },
  },
  computed: {
    formatParameter() {
      return sprintf(__(`%{stageName} Job - %{jobName}`), {
        stageName: capitalizeFirstCharacter(this.stage),
        jobName: this.jobName,
      });
    },
  },
};
</script>

<template>
  <span data-testid="ci-lint-parameter">{{ formatParameter }}</span>
</template>
