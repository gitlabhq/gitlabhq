<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';
import { getVerificationLevelOptions } from '../../constants';

export default {
  name: 'VerificationLevelToken',
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
    levels() {
      return getVerificationLevelOptions();
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="glListeners()">
    <template #suggestions>
      <gl-filtered-search-suggestion v-for="level in levels" :key="level.value" :value="level.text">
        {{ level.text }}
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
