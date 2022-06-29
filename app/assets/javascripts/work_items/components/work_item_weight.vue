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
  <div v-if="hasIssueWeightsFeature" class="gl-mb-5 form-row">
    <span class="gl-font-weight-bold col-lg-2 col-3 gl-overflow-wrap-break">{{
      __('Weight')
    }}</span>
    <span class="gl-ml-5">{{ weightText }}</span>
  </div>
</template>
