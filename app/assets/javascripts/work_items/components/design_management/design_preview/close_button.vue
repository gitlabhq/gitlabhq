<script>
import { GlButton } from '@gitlab/ui';
import { ROUTES } from '../../../constants';

export default {
  components: {
    GlButton,
  },
  ROUTES,
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
        name: $options.ROUTES.workItem,
        query: $route.query,
      }"
    />
  </div>
</template>
