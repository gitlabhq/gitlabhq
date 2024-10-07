<script>
import { GlIcon } from '@gitlab/ui';
import { ROUTES } from '../../../constants';

export default {
  components: {
    GlIcon,
  },
  ROUTES,
};
</script>

<template>
  <div class="gl-border-l">
    <router-link
      :to="{
        name: $options.ROUTES.workItem,
        query: $route.query,
      }"
      :aria-label="s__('DesignManagement|Go back to designs')"
      class="btn btn-icon gl-mx-3 gl-border-0 gl-px-3"
    >
      <gl-icon name="close" />
    </router-link>
  </div>
</template>
