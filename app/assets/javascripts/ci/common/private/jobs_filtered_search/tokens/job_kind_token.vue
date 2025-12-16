<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'JobKindToken',
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    jobKinds() {
      return [
        {
          text: s__('Job|Build'),
          value: 'BUILD',
        },
        {
          text: s__('Job|Trigger'),
          value: 'BRIDGE',
        },
      ];
    },
    activeJobKind() {
      return this.jobKinds.find((kind) => kind.value === this.value.data) || {};
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view>
      <div class="gl-flex gl-items-center">
        <span data-testid="job-kind-text">{{ activeJobKind.text }}</span>
      </div>
    </template>

    <template #suggestions>
      <gl-filtered-search-suggestion v-for="kind in jobKinds" :key="kind.value" :value="kind.value">
        {{ kind.text }}
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
