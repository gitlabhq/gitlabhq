<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { PACKAGE_TYPES } from '~/packages_and_registries/package_registry/constants';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
  },
  PACKAGE_TYPES,
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$attrs }" v-on="$listeners">
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="(type, index) in $options.PACKAGE_TYPES"
        :key="index"
        :value="type"
      >
        {{ type }}
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
