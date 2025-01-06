<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
};
</script>
<template>
  <gl-icon v-bind="$attrs" name="question-o" :size="16" variant="info" class="gl-cursor-help" />
</template>
