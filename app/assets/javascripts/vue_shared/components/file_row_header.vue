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
  <div class="file-row-header gl-bg-white sticky-top gl-px-2 js-file-row-header" :title="path">
    <gl-truncate :text="path" position="middle" class="gl-font-bold" />
  </div>
</template>
