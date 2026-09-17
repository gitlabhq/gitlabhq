<script>
import { GlLink } from '@gitlab/ui';

export default {
  name: 'DashboardsListNameCell',
  components: {
    GlLink,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    dashboardUrl: {
      type: String,
      required: true,
    },
    // Opt-in because the cell also renders inside GlTable rows, which are
    // not positioned, so a stretched link there would cover the whole table.
    stretched: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div class="gl-min-w-0">
    <gl-link
      data-testid="dashboard-redirect-link"
      :href="dashboardUrl"
      class="gl-text-lg gl-font-bold !gl-text-strong !gl-no-underline"
      :class="{ 'gl-stretched-link': stretched }"
      >{{ name }}</gl-link
    >
    <p
      v-if="description"
      class="gl-m-0 gl-line-clamp-2 gl-text-subtle"
      data-testid="dashboard-description"
    >
      {{ description }}
    </p>
  </div>
</template>
