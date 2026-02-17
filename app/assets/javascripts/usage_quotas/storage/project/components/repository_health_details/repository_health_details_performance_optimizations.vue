<script>
import { GlIcon } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import RepositoryHealthPerformanceCard from './repository_health_details_performance_card.vue';

export default {
  name: 'RepositoryHealthPerformanceOptimizations',
  components: {
    GlIcon,
    RepositoryHealthPerformanceCard,
  },
  props: {
    healthDetails: {
      type: Object,
      required: true,
    },
  },
  computed: {
    commitGraphFeatures() {
      if (!this.healthDetails?.commitGraph) {
        return [];
      }

      return [
        {
          label: s__('UsageQuota|Bloom filters'),
          enabled: this.healthDetails.commitGraph.hasBloomFilters,
        },
        {
          label: s__('UsageQuota|Generation data'),
          enabled: this.healthDetails.commitGraph.hasGenerationData,
        },
        {
          label: s__('UsageQuota|Generation data overflow'),
          enabled: this.healthDetails.commitGraph.hasGenerationDataOverflow,
        },
      ];
    },
    commitGraphFooterText() {
      if (!this.healthDetails?.commitGraph) {
        return null;
      }

      return sprintf(s__('UsageQuota|Chain length: %{value}'), {
        value: this.healthDetails.commitGraph.commitGraphChainLength,
      });
    },
    reachabilityBitmapFeatures() {
      if (!this.healthDetails?.bitmap) {
        return [];
      }

      return [
        {
          label: s__('UsageQuota|Hash cache'),
          enabled: this.healthDetails.bitmap.hasHashCache,
        },
        {
          label: s__('UsageQuota|Lookup table'),
          enabled: this.healthDetails.bitmap.hasLookupTable,
        },
      ];
    },
    multiPackIndexBitmapFeatures() {
      if (!this.healthDetails?.multiPackIndexBitmap) {
        return [];
      }

      return [
        {
          label: s__('UsageQuota|Hash cache'),
          enabled: this.healthDetails.multiPackIndexBitmap.hasHashCache,
        },
        {
          label: s__('UsageQuota|Lookup table'),
          enabled: this.healthDetails.multiPackIndexBitmap.hasLookupTable,
        },
      ];
    },
    multiPackIndexFooterText() {
      if (!this.healthDetails?.multiPackIndex) {
        return null;
      }

      return sprintf(s__('UsageQuota|Packfile count: %{value}'), {
        value: this.healthDetails.multiPackIndex.packfileCount,
      });
    },
  },
};
</script>

<template>
  <div class="gl-my-6">
    <h6 class="gl-mb-5" data-testid="performance-header-text">
      <gl-icon name="dashboard" class="gl-mr-3" />{{ s__('UsageQuota|Performance optimizations') }}
    </h6>
    <div class="gl-grid gl-gap-4 md:gl-grid-cols-2">
      <repository-health-performance-card
        data-testid="commit-graph-features"
        :header-text="s__('UsageQuota|Commit graph')"
        :features="commitGraphFeatures"
        :footer-text="commitGraphFooterText"
        :no-features-text="
          s__(
            'UsageQuota|No commit graph detected. A commit graph file can significantly speed up Git operations like log, merge-base, and push by pre-computing and caching commit metadata.',
          )
        "
      />
      <repository-health-performance-card
        data-testid="reachability-bitmap-features"
        :header-text="s__('UsageQuota|Reachability bitmap')"
        :features="reachabilityBitmapFeatures"
        :no-features-text="
          s__(
            'UsageQuota|No reachability bitmap detected. A reachability bitmap can accelerate Git operations that need to determine object reachability, improving performance for clones, fetches, and pushes.',
          )
        "
      />
      <repository-health-performance-card
        data-testid="multi-pack-bitmap-features"
        :header-text="s__('UsageQuota|Multi-pack index bitmap')"
        :features="multiPackIndexBitmapFeatures"
        :footer-text="multiPackIndexFooterText"
        :no-features-text="
          s__(
            'UsageQuota|No multi-pack index bitmap detected. A multi-pack index bitmap can improve object lookup performance across multiple pack files, particularly benefiting fetch and clone operations.',
          )
        "
      />
    </div>
  </div>
</template>
