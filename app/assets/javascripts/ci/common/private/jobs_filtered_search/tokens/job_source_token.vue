<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { JOB_SOURCES } from 'ee_else_ce/ci/common/private/jobs_filtered_search/tokens/constants';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

export default {
  name: 'JobSourceToken',
  JOB_SOURCES,
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
  },
  mixins: [glListenersMixin],
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
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="glListeners()">
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
