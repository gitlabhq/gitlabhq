<script>
import { GlTruncate } from '@gitlab/ui';

export default {
  components: {
    GlTruncate,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="file-row-header sticky-top js-file-row-header gl-bg-white gl-px-2" :title="path">
    <gl-truncate :text="path" position="middle" class="gl-font-bold" />
  </div>
</template>
