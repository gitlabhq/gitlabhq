<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { JOB_SOURCES } from 'ee_else_ce/ci/common/private/jobs_filtered_search/tokens/constants';

export default {
  JOB_SOURCES,
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
    activeSource() {
      return JOB_SOURCES.find((source) => source.value === this.value.data) || {};
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view>
      <div class="gl-flex gl-items-center">
        <span data-testid="job-source-text">{{ activeSource.text }}</span>
      </div>
    </template>

    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="source in $options.JOB_SOURCES"
        :key="source.value"
        :value="source.value"
      >
        {{ source.text }}
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
