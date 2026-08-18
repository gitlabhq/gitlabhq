<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

export default {
  name: 'AddContextCommitsToken',
  components: {
    GlFilteredSearchToken,
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
  data() {
    return {
      val: '',
    };
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="glListeners()" />
</template>
