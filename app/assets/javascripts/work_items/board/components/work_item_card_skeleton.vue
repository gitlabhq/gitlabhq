<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'WorkItemCardSkeleton',
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <li
    class="gl-border gl-rounded-lg gl-border-section gl-bg-section gl-p-3"
    data-testid="work-item-card-skeleton"
  >
    <gl-skeleton-loader :width="140" :height="38">
      <!-- work item type icon + title -->
      <rect x="0" y="0" width="8" height="8" rx="4" />
      <rect x="10" y="0" width="104" height="8" rx="3" />
      <!-- reference -->
      <rect x="0" y="12" width="54" height="8" rx="3" />
      <!-- label -->
      <rect x="0" y="22" width="34" height="8" rx="3" />
      <!-- assignee avatars -->
      <rect x="120" y="32" width="20" height="6" rx="3" />
    </gl-skeleton-loader>
  </li>
</template>
