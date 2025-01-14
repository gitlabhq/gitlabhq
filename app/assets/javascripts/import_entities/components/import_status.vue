<script>
import { GlAccordion, GlAccordionItem, GlBadge, GlIcon, GlLink } from '@gitlab/ui';

import { STATISTIC_ITEMS } from '~/import/constants';
import { STATUSES, STATUS_ICON_MAP } from '../constants';

function isIncompleteImport(stats) {
  return Object.keys(stats?.fetched ?? []).some(
    (key) => stats.fetched[key] !== stats.imported[key],
  );
}

export default {
  name: 'ImportStatus',
  components: {
    GlAccordion,
    GlAccordionItem,
    GlBadge,
    GlIcon,
    GlLink,
  },
  inject: {
    detailsPath: {
      default: undefined,
    },
  },
  props: {
    projectId: {
      type: Number,
      required: false,
      default: null,
    },
    status: {
      type: String,
      required: true,
    },
    stats: {
      type: Object,
      required: false,
      default: () => ({ fetched: {}, imported: {} }),
    },
  },

  computed: {
    knownStats() {
      const knownStatisticKeys = Object.keys(STATISTIC_ITEMS);
      return Object.keys(this.stats?.fetched ?? []).filter((key) =>
        knownStatisticKeys.includes(key),
      );
    },

    hasStats() {
      return this.stats && this.knownStats.length > 0;
    },

    isIncomplete() {
      return this.status === STATUSES.FINISHED && this.stats && isIncompleteImport(this.stats);
    },

    mappedStatus() {
      if (this.isIncomplete) {
        return STATUS_ICON_MAP[STATUSES.PARTIAL];
      }

      return STATUS_ICON_MAP[this.status];
    },

    showDetails() {
      return Boolean(this.detailsPathForProject) && this.isIncomplete;
    },

    detailsPathForProject() {
      if (!this.projectId || !this.detailsPath) {
        return null;
      }

      return `${this.detailsPath}?project_id=${this.projectId}`;
    },
  },

  methods: {
    getStatisticIconProps(key) {
      const fetched = this.stats.fetched[key];
      const imported = this.stats.imported[key];

      if (fetched === imported) {
        return { name: 'status-success', variant: 'success' };
      }
      if (imported === 0) {
        return { name: 'status-scheduled', variant: 'subtle' };
      }
      if (this.status === STATUSES.FINISHED) {
        return { name: 'status-alert', variant: 'warning' };
      }

      return { name: 'status-running', variant: 'info' };
    },
  },

  STATISTIC_ITEMS,
};
</script>

<template>
  <div>
    <div class="gl-inline-block">
      <gl-badge :icon="mappedStatus.icon" :variant="mappedStatus.variant" icon-size="sm">
        {{ mappedStatus.text }}
      </gl-badge>
    </div>
    <gl-accordion v-if="hasStats" :header-level="3">
      <gl-accordion-item :title="__('Details')">
        <ul class="gl-mb-3 gl-list-none gl-p-0 gl-text-sm">
          <li v-for="key in knownStats" :key="key">
            <div class="gl-flex gl-w-20 gl-items-center">
              <gl-icon :size="12" class="gl-mr-3 gl-shrink-0" v-bind="getStatisticIconProps(key)" />
              <span class="">{{ $options.STATISTIC_ITEMS[key] }}</span>
              <span class="gl-ml-auto">
                {{ stats.imported[key] || 0 }}/{{ stats.fetched[key] }}
              </span>
            </div>
          </li>
        </ul>
        <gl-link v-if="showDetails" :href="detailsPathForProject"
          >{{ s__('Import|Show errors') }} &gt;</gl-link
        >
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
