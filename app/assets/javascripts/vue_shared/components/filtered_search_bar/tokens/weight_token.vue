<script>
import { GlDropdownDivider, GlFilteredSearchSuggestion, GlFilteredSearchToken } from '@gitlab/ui';
import { DEFAULT_NONE_ANY, WEIGHT_TOKEN_SUGGESTIONS_SIZE } from '../constants';

const weights = Array.from(Array(WEIGHT_TOKEN_SUGGESTIONS_SIZE), (_, index) => index.toString());

export default {
  components: {
    GlDropdownDivider,
    GlFilteredSearchSuggestion,
    GlFilteredSearchToken,
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
  data() {
    return {
      weights,
      defaultWeights: this.config.defaultWeights || DEFAULT_NONE_ANY,
    };
  },
  methods: {
    updateWeights({ data }) {
      const weight = parseInt(data, 10);
      this.weights = Number.isNaN(weight) ? weights : [String(weight)];
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="updateWeights"
  >
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="weight in defaultWeights"
        :key="weight.value"
        :value="weight.value"
      >
        {{ weight.text }}
      </gl-filtered-search-suggestion>
      <gl-dropdown-divider v-if="defaultWeights.length" />
      <gl-filtered-search-suggestion v-for="weight of weights" :key="weight" :value="weight">
        {{ weight }}
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
