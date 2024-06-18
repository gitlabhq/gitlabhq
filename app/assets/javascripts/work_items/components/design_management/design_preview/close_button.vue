<script>
import { GlIcon } from '@gitlab/ui';
import { WORK_ITEM_ROUTE_NAME } from '../../../constants';

export default {
  components: {
    GlIcon,
  },
  WORK_ITEM_ROUTE_NAME,
};
</script>

<template>
  <div class="gl-border-l">
    <router-link
      :to="{
        name: $options.WORK_ITEM_ROUTE_NAME,
        query: $route.query,
      }"
      :aria-label="s__('DesignManagement|Go back to designs')"
      class="btn btn-icon gl-px-3 gl-mx-3 gl-border-0"
    >
      <gl-icon name="close" />
    </router-link>
  </div>
</template>
