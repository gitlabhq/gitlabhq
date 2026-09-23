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
      class="gl-font-bold !gl-text-strong gl-break-anywhere"
      :class="{ 'gl-stretched-link': stretched }"
      >{{ name }}</gl-link
    >
    <!-- The native title recovers the clamped text; a stretched link can cover
         the paragraph, so it cannot be selected or hovered as a GlTooltip target. -->
    <p
      v-if="description"
      :title="description"
      class="gl-m-0 gl-line-clamp-2 gl-text-sm gl-text-subtle gl-break-anywhere"
      data-testid="dashboard-description"
    >
      {{ description }}
    </p>
  </div>
</template>
