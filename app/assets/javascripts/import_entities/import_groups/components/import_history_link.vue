<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },

  props: {
    id: {
      type: Number,
      required: false,
      default: null,
    },
    historyPath: {
      type: String,
      required: true,
    },
  },

  computed: {
    historyPathWithId() {
      return this.historyPath.replace(':id', encodeURIComponent(this.id));
    },
  },
};
</script>
<template>
  <gl-button :href="historyPathWithId">{{ s__('BulkImport|Migration details') }}</gl-button>
</template>
