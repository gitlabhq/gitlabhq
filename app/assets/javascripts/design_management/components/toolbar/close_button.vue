<script>
import { GlIcon } from '@gitlab/ui';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    GlIcon,
  },
  DESIGNS_ROUTE_NAME,
};
</script>

<template>
  <div class="gl-border-l">
    <router-link
      :to="{
        name: $options.DESIGNS_ROUTE_NAME,
        query: $route.query,
      }"
      :aria-label="s__('DesignManagement|Go back to designs')"
      data-testid="close-design"
      class="btn btn-icon gl-mx-3 gl-border-0 gl-px-3"
      tag="button"
    >
      <gl-icon name="close" />
    </router-link>
  </div>
</template>
