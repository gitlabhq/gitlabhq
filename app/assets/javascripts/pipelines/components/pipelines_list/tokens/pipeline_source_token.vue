<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
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
    sources() {
      return [
        {
          text: s__('Pipeline|Source|Push'),
          value: 'push',
        },
        {
          text: s__('Pipeline|Source|Web'),
          value: 'web',
        },
        {
          text: s__('Pipeline|Source|Trigger'),
          value: 'trigger',
        },
        {
          text: s__('Pipeline|Source|Schedule'),
          value: 'schedule',
        },
        {
          text: s__('Pipeline|Source|API'),
          value: 'api',
        },
        {
          text: s__('Pipeline|Source|External'),
          value: 'external',
        },
        {
          text: s__('Pipeline|Source|Pipeline'),
          value: 'pipeline',
        },
        {
          text: s__('Pipeline|Source|Chat'),
          value: 'chat',
        },
        {
          text: s__('Pipeline|Source|Web IDE'),
          value: 'webide',
        },
        {
          text: s__('Pipeline|Source|Merge Request'),
          value: 'merge_request_event',
        },
        {
          text: s__('Pipeline|Source|External Pull Request'),
          value: 'external_pull_request_event',
        },
        {
          text: s__('Pipeline|Source|Parent Pipeline'),
          value: 'parent_pipeline',
        },
        {
          text: s__('Pipeline|Source|On-Demand DAST Scan'),
          value: 'ondemand_dast_scan',
        },
        {
          text: s__('Pipeline|Source|On-Demand DAST Validation'),
          value: 'ondemand_dast_validation',
        },
      ];
    },
    findActiveSource() {
      return this.sources.find((source) => source.value === this.value.data);
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view>
      <div class="gl-display-flex gl-align-items-center">
        <span>{{ findActiveSource.text }}</span>
      </div>
    </template>

    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="source in sources"
        :key="source.value"
        :value="source.value"
      >
        {{ source.text }}
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
