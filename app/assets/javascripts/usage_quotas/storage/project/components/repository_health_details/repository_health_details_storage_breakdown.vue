<script>
import { GlIcon, GlCard, GlSprintf, GlProgressBar } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { isNumber } from 'lodash';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { formatNumber, __ } from '~/locale';

export default {
  name: 'RepositoryHealthDetailsStorageBreakdown',
  components: {
    GlIcon,
    GlCard,
    GlSprintf,
    GlProgressBar,
    GlSingleStat,
  },
  props: {
    healthDetails: {
      type: Object,
      required: true,
    },
  },
  computed: {
    references() {
      return this.healthDetails.references || {};
    },
    objects() {
      return this.healthDetails.objects || {};
    },
  },
  methods: {
    calculatePercentage(value1, value2) {
      if (!isNumber(value1) || !isNumber(value2) || value2 === 0) {
        return __('Unknown');
      }

      const percent = value1 / value2;
      return formatNumber(percent, {
        style: 'percent',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
    },
    formatNumberToHumanSize(value) {
      return isNumber(value) ? numberToHumanSize(value) : __('Unknown');
    },
  },
};
</script>

<template>
  <div class="gl-mb-6">
    <div class="gl-mb-5 gl-flex gl-items-center">
      <h6 data-testid="repository-health-storage-title">
        <gl-icon name="disk" class="gl-mr-3" />{{ s__('UsageQuota|Storage breakdown') }}
      </h6>
    </div>
    <div class="gl-grid gl-gap-4 md:gl-grid-cols-2">
      <gl-card class="gl-bg-white" data-testid="repository-health-storage-object-storage-card">
        <gl-single-stat
          :value="formatNumberToHumanSize(objects.size)"
          :title="s__('UsageQuota|Objects storage')"
          :should-animate="false"
        />
        <p class="gl-mb-0 gl-mt-2 gl-px-2 gl-text-subtle">
          <gl-sprintf :message="s__('UsageQuota|%{percent} of total')">
            <template #percent>
              {{ calculatePercentage(objects.size, healthDetails.size) }}
            </template>
          </gl-sprintf>
        </p>
      </gl-card>
      <gl-card class="gl-bg-white" data-testid="repository-health-storage-references-card">
        <gl-single-stat
          :value="formatNumberToHumanSize(references.packedSize)"
          :title="s__('UsageQuota|References')"
          :should-animate="false"
        />
        <p class="gl-mb-0 gl-mt-2 gl-px-2 gl-text-subtle">
          <gl-sprintf :message="s__('UsageQuota|%{value} loose refs')">
            <template #value>
              {{ references.looseCount || 0 }}
            </template>
          </gl-sprintf>
        </p>
      </gl-card>
    </div>
    <gl-card class="gl-mt-4 gl-bg-white">
      <div class="gl-my-5" data-testid="repository-health-storage-recent-objects">
        <div class="gl-flex gl-items-center">
          <span class="gl-mb-3 gl-text-sm gl-font-300">{{ s__('UsageQuota|Recent objects') }}</span>
          <span
            class="gl-ml-auto gl-text-sm gl-font-300 gl-text-green-600"
            data-testid="repository-health-storage-recent-objects-percentage"
            >{{ formatNumberToHumanSize(objects.recentSize) }} ({{
              calculatePercentage(objects.recentSize, objects.size)
            }})</span
          >
        </div>
        <gl-progress-bar
          :aria-label="s__('UsageQuota|Recent objects progress bar')"
          :value="calculatePercentage(objects.recentSize, objects.size)"
          variant="success"
        />
      </div>
      <div class="gl-my-5" data-testid="repository-health-storage-stale-objects">
        <div class="gl-flex gl-items-center">
          <span class="gl-mb-3 gl-text-sm gl-font-300">{{ s__('UsageQuota|Stale objects') }}</span>
          <span
            class="gl-ml-auto gl-text-sm gl-font-300"
            data-testid="repository-health-storage-stale-objects-percentage"
            >{{ formatNumberToHumanSize(objects.staleSize) }} ({{
              calculatePercentage(objects.staleSize, objects.size)
            }})</span
          >
        </div>
        <gl-progress-bar
          :aria-label="s__('UsageQuota|Stale objects progress bar')"
          :value="calculatePercentage(objects.staleSize, objects.size)"
          variant="warning"
        />
      </div>
    </gl-card>
  </div>
</template>
