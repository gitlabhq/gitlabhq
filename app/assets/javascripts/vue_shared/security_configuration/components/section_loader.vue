<script>
import { GlCard, GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'SectionLoader',
  components: {
    GlCard,
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div>
    <gl-skeleton-loader :width="1248" :height="180">
      <rect x="0" y="0" width="100" height="15" rx="4" />
      <rect x="0" y="24" width="460" height="32" rx="4" />
      <rect x="0" y="71" width="100" height="15" rx="4" />
      <rect x="0" y="95" width="460" height="72" rx="4" />
    </gl-skeleton-loader>
    <gl-card v-for="i in 2" :key="i" class="gl-mb-5">
      <template #header>
        <gl-skeleton-loader :width="1248" :height="15">
          <rect x="0" y="0" width="300" height="15" rx="4" />
        </gl-skeleton-loader>
      </template>
      <gl-skeleton-loader :width="1248" :height="15">
        <rect x="0" y="0" width="600" height="15" rx="4" />
      </gl-skeleton-loader>
      <gl-skeleton-loader :width="1248" :height="15">
        <rect x="0" y="0" width="300" height="15" rx="4" />
      </gl-skeleton-loader>
    </gl-card>
  </div>
</template>
