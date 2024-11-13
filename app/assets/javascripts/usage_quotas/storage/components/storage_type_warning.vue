<script>
import { GlIcon, GlPopover } from '@gitlab/ui';

export default {
  name: 'StorageTypeWarning',
  components: {
    GlPopover,
    GlIcon,
  },
  data() {
    return {
      mounted: false,
    };
  },
  mounted() {
    this.mounted = true;
  },
};
</script>

<template>
  <span>
    <gl-icon ref="glIcon" name="warning" class="gl-ml-2" variant="subtle" />
    <gl-popover v-if="mounted" :target="$refs.glIcon" triggers="hover focus" placement="top">
      <slot></slot>
    </gl-popover>
  </span>
</template>
