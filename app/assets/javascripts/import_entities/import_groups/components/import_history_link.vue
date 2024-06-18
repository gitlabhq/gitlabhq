<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
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
  <gl-link :href="historyPathWithId">{{ s__('BulkImport|Migration details') }} &gt;</gl-link>
</template>
