<script>
import { GlFilteredSearchToken } from '@gitlab/ui';

export default {
  name: 'AddContextCommitsToken',
  components: {
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
      val: '',
    };
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners" />
</template>
