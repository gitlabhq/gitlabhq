<script>
import { GlCard, GlSkeletonLoader } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';

export default {
  name: 'StorageUsageOverviewCard',
  components: {
    GlCard,
    GlSkeletonLoader,
    NumberToHumanSize,
  },
  props: {
    usedStorage: {
      type: Number,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <gl-card>
    <gl-skeleton-loader v-if="loading" :height="64">
      <rect width="140" height="30" x="5" y="0" rx="4" />
      <rect width="240" height="10" x="5" y="40" rx="4" />
      <rect width="340" height="10" x="5" y="54" rx="4" />
    </gl-skeleton-loader>

    <div v-else>
      <div class="gl-font-bold" data-testid="namespace-storage-card-title">
        {{ s__('UsageQuota|Namespace storage used') }}
      </div>
      <div class="gl-my-3 gl-text-size-h-display gl-font-bold gl-leading-1">
        <number-to-human-size label-class="gl-text-lg" :value="Number(usedStorage)" plain-zero />
      </div>
      <hr class="gl-my-4" />
      <p>
        {{
          s__(
            'UsageQuota|Namespace total storage represents the sum of storage consumed by all projects, Container Registry, and Dependency Proxy.',
          )
        }}
      </p>
    </div>
  </gl-card>
</template>
