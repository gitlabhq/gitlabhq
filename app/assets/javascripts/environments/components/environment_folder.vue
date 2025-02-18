<script>
import { GlIcon, GlBadge, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlBadge,
    GlLink,
  },
  props: {
    nestedEnvironment: {
      type: Object,
      required: true,
    },
  },
  computed: {
    totalEnvironmentsCount() {
      return this.nestedEnvironment.size;
    },
    folderPath() {
      return this.nestedEnvironment.latest.folderPath;
    },
  },
};
</script>
<template>
  <div class="gl-border-b gl-p-4">
    <gl-icon class="gl-mr-2" name="folder" variant="subtle" />
    <gl-link :href="folderPath">
      {{ nestedEnvironment.name }}
      <gl-badge class="gl-ml-2">{{ totalEnvironmentsCount }}</gl-badge>
    </gl-link>
  </div>
</template>
