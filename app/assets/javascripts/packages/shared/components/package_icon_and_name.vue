<script>
import { GlIcon } from '@gitlab/ui';

export default {
  name: 'PackageIconAndName',
  components: {
    GlIcon,
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <gl-icon name="package" class="gl-ml-3 gl-mr-2" />
    <span><slot></slot></span>
  </div>
</template>
