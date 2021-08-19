<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { DEFAULT_NONE_ANY, WEIGHT_TOKEN_SUGGESTIONS_SIZE } from '../constants';

const weights = Array.from(Array(WEIGHT_TOKEN_SUGGESTIONS_SIZE), (_, index) => index.toString());

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
      weights,
    };
  },
  computed: {
    defaultWeights() {
      return this.config.defaultWeights || DEFAULT_NONE_ANY;
    },
  },
  methods: {
    getActiveWeight(weightSuggestions, data) {
      return weightSuggestions.find((weight) => weight === data);
    },
    updateWeights(searchTerm) {
      const weight = parseInt(searchTerm, 10);
      this.weights = Number.isNaN(weight) ? weights : [String(weight)];
    },
  },
};
</script>

<template>
  <base-token
    :active="active"
    :config="config"
    :value="value"
    :default-suggestions="defaultWeights"
    :suggestions="weights"
    :get-active-token-value="getActiveWeight"
    @fetch-suggestions="updateWeights"
    v-on="$listeners"
  >
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion v-for="weight of suggestions" :key="weight" :value="weight">
        {{ weight }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
