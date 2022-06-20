<script>
import { __ } from '~/locale';

export default {
  inject: ['hasIssueWeightsFeature'],
  props: {
    weight: {
      type: Number,
      required: false,
      default: undefined,
    },
  },
  computed: {
    weightText() {
      return this.weight ?? __('None');
    },
  },
};
</script>

<template>
  <div v-if="hasIssueWeightsFeature" class="gl-mb-5">
    <span class="gl-display-inline-block gl-font-weight-bold gl-w-15">{{ __('Weight') }}</span>
    {{ weightText }}
  </div>
</template>
