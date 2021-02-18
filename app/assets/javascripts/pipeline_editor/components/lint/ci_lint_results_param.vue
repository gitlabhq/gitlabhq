<script>
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { __ } from '~/locale';

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
      return __(`${capitalizeFirstCharacter(this.stage)} Job - ${this.jobName}`);
    },
  },
};
</script>

<template>
  <span data-testid="ci-lint-parameter">{{ formatParameter }}</span>
</template>
