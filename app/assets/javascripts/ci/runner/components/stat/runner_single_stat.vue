<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { formatNumber } from '~/locale';
import RunnerCount from './runner_count.vue';

export default {
  components: {
    GlSingleStat,
    RunnerCount,
  },
  props: {
    scope: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    skip: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    formattedValue(value) {
      if (typeof value === 'number') {
        return formatNumber(value);
      }
      return '-';
    },
  },
};
</script>
<template>
  <runner-count #default="{ count }" :scope="scope" :variables="variables" :skip="skip">
    <gl-single-stat v-bind="$attrs" :value="formattedValue(count)" />
  </runner-count>
</template>
