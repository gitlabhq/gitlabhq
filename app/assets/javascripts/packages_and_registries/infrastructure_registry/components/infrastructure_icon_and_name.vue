<script>
import { GlIcon } from '@gitlab/ui';

export default {
  name: 'InfrastructureIconAndName',
  components: {
    GlIcon,
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <gl-icon name="infrastructure-registry" class="gl-ml-3 gl-mr-2" />
    <span>{{ s__('InfrastructureRegistry|Terraform') }}</span>
  </div>
</template>
