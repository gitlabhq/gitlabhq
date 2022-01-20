<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    lines: {
      type: Number,
      required: true,
    },
  },
};
</script>
<template>
  <div class="line-numbers">
    <gl-link
      v-for="line in lines"
      :id="`L${line}`"
      :key="line"
      class="diff-line-num gl-shadow-none!"
      :to="`#LC${line}`"
      :data-line-number="line"
    >
      <gl-icon :size="12" name="link" />
      {{ line }}
    </gl-link>
  </div>
</template>
