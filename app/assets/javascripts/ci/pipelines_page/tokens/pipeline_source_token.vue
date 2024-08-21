<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { PIPELINE_SOURCES } from 'ee_else_ce/ci/pipelines_page/tokens/constants';

export default {
  PIPELINE_SOURCES,
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
      return PIPELINE_SOURCES.find((source) => source.value === this.value.data);
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view>
      <div class="gl-flex gl-items-center">
        <span>{{ activeSource.text }}</span>
      </div>
    </template>

    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="source in $options.PIPELINE_SOURCES"
        :key="source.value"
        :value="source.value"
      >
        {{ source.text }}
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
