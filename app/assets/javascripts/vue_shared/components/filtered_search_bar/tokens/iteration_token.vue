<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { DEFAULT_ITERATIONS } from '../constants';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      iterations: this.config.initialIterations || [],
      loading: false,
    };
  },
  computed: {
    defaultIterations() {
      return this.config.defaultIterations || DEFAULT_ITERATIONS;
    },
  },
  methods: {
    getActiveIteration(iterations, data) {
      return iterations.find((iteration) => this.getValue(iteration) === data);
    },
    fetchIterations(searchTerm) {
      this.loading = true;
      this.config
        .fetchIterations(searchTerm)
        .then((response) => {
          this.iterations = Array.isArray(response) ? response : response.data;
        })
        .catch(() => {
          createFlash({ message: __('There was a problem fetching iterations.') });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    getValue(iteration) {
      return String(getIdFromGraphQLId(iteration.id));
    },
  },
};
</script>

<template>
  <base-token
    :active="active"
    :config="config"
    :value="value"
    :default-suggestions="defaultIterations"
    :suggestions="iterations"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveIteration"
    @fetch-suggestions="fetchIterations"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? activeTokenValue.title : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="iteration in suggestions"
        :key="iteration.id"
        :value="getValue(iteration)"
      >
        {{ iteration.title }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
