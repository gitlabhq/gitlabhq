<script>
import { GlLink } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';

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
      return mergeUrlParams({ bulk_import_id: this.id }, this.historyPath);
    },
  },
};
</script>
<template>
  <gl-link :href="historyPathWithId">{{ __('View details') }}</gl-link>
</template>
