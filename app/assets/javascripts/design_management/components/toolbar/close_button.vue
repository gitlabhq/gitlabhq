<script>
import { GlButton } from '@gitlab/ui';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    GlButton,
  },
  DESIGNS_ROUTE_NAME,
};
</script>

<template>
  <div class="gl-border-l">
    <gl-button
      :aria-label="s__('DesignManagement|Go back to designs')"
      data-testid="close-design"
      class="gl-mx-3"
      icon="close"
      category="tertiary"
      :to="{
        name: $options.DESIGNS_ROUTE_NAME,
        query: $route.query,
      }"
    />
  </div>
</template>
