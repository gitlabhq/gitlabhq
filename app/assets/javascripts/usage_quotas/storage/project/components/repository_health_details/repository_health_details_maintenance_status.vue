<script>
import { GlIcon, GlCard } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';
import { LONG_DATE_FORMAT_WITH_TZ } from '~/vue_shared/constants';
import { __, s__ } from '~/locale';

export default {
  name: 'RepositoryHealthMaintenanceStatus',
  components: {
    GlIcon,
    GlCard,
    GlSingleStat,
  },
  props: {
    healthDetails: {
      type: Object,
      required: true,
    },
  },
  computed: {
    objects() {
      return this.healthDetails?.objects || {};
    },
    lastFullRepack() {
      const timeInSeconds = this.healthDetails?.lastFullRepack?.seconds;

      return timeInSeconds ? new Date(timeInSeconds * 1000) : null;
    },
    lastFullRepackTimeAgo() {
      return this.lastFullRepack ? getTimeago().format(this.lastFullRepack) : __('Unknown');
    },
    lastFullRepackDateString() {
      return this.lastFullRepack ? formatDate(this.lastFullRepack, LONG_DATE_FORMAT_WITH_TZ) : '';
    },
    objectStats() {
      return [
        { value: this.objects?.packfileCount || 0, title: s__('UsageQuota|Packfiles') },
        { value: this.objects?.cruftCount || 0, title: s__('UsageQuota|Cruft packs') },
        { value: this.objects?.looseObjectsCount || 0, title: s__('UsageQuota|Loose objects') },
      ];
    },
  },
};
</script>

<template>
  <div class="gl-my-6">
    <h5 class="gl-mb-5" data-testid="maintenance-status-header">
      <gl-icon name="work" class="gl-mr-3" />{{ s__('UsageQuota|Maintenance status') }}
    </h5>
    <div class="gl-grid gl-gap-4 md:gl-grid-cols-2">
      <gl-card class="gl-justify-center gl-bg-white" data-testid="references-card">
        <gl-single-stat
          :value="lastFullRepackTimeAgo"
          :title="s__('UsageQuota|Last full repack')"
          :should-animate="false"
        />
        <p
          v-if="lastFullRepackDateString"
          class="gl-mb-0 gl-mt-2 gl-text-subtle"
          data-testid="last-full-repack-date-string"
        >
          {{ lastFullRepackDateString }}
        </p>
      </gl-card>
      <gl-card class="gl-bg-white" data-testid="object-packing-card">
        <h6 class="gl-mt-0 gl-text-sm gl-font-300">{{ s__('UsageQuota|Object packing') }}</h6>
        <div class="gl-grid gl-grid-cols-3 gl-gap-4">
          <div
            v-for="stat in objectStats"
            :key="stat.title"
            class="gl-mx-auto gl-text-center"
            data-testid="object-packing-stat"
          >
            <p class="gl-text-600-fixed gl-font-bold">{{ stat.value }}</p>
            <p class="gl-text-sm gl-font-300">{{ stat.title }}</p>
          </div>
        </div>
      </gl-card>
    </div>
  </div>
</template>
