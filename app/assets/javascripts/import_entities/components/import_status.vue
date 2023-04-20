<script>
import { GlAccordion, GlAccordionItem, GlBadge, GlIcon, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { STATISTIC_ITEMS } from '~/import/constants';
import { STATUSES } from '../constants';

const SCHEDULED_STATUS = {
  icon: 'status-scheduled',
  text: __('Pending'),
  variant: 'muted',
};

const STATUS_MAP = {
  [STATUSES.NONE]: {
    icon: 'status-waiting',
    text: __('Not started'),
    variant: 'muted',
  },
  [STATUSES.SCHEDULING]: SCHEDULED_STATUS,
  [STATUSES.SCHEDULED]: SCHEDULED_STATUS,
  [STATUSES.CREATED]: SCHEDULED_STATUS,
  [STATUSES.STARTED]: {
    icon: 'status-running',
    text: __('Importing...'),
    variant: 'info',
  },
  [STATUSES.FAILED]: {
    icon: 'status-failed',
    text: __('Failed'),
    variant: 'danger',
  },
  [STATUSES.TIMEOUT]: {
    icon: 'status-failed',
    text: __('Timeout'),
    variant: 'danger',
  },
  [STATUSES.CANCELED]: {
    icon: 'status-stopped',
    text: __('Cancelled'),
    variant: 'neutral',
  },
};

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
  mixins: [glFeatureFlagMixin()],
  inject: {
    detailsPath: {
      default: undefined,
    },
  },
  props: {
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
      if (this.status === STATUSES.FINISHED) {
        return this.isIncomplete
          ? {
              icon: 'status-alert',
              text: s__('Import|Partially completed'),
              variant: 'warning',
            }
          : {
              icon: 'status-success',
              text: __('Complete'),
              variant: 'success',
            };
      }

      return STATUS_MAP[this.status];
    },

    showDetails() {
      return Boolean(this.detailsPath) && this.glFeatures.importDetailsPage && this.isIncomplete;
    },
  },

  methods: {
    getStatisticIconProps(key) {
      const fetched = this.stats.fetched[key];
      const imported = this.stats.imported[key];

      if (fetched === imported) {
        return { name: 'status-success', class: 'gl-text-green-400' };
      } else if (imported === 0) {
        return { name: 'status-scheduled', class: 'gl-text-gray-400' };
      } else if (this.status === STATUSES.FINISHED) {
        return { name: 'status-alert', class: 'gl-text-orange-400' };
      }

      return { name: 'status-running', class: 'gl-text-blue-400' };
    },
  },

  STATISTIC_ITEMS,
  i18n: {
    detailsLink: s__('Import|See failures'),
  },
};
</script>

<template>
  <div>
    <div class="gl-display-inline-block">
      <gl-badge :icon="mappedStatus.icon" :variant="mappedStatus.variant" size="md" icon-size="sm">
        {{ mappedStatus.text }}
      </gl-badge>
    </div>
    <gl-accordion v-if="hasStats" :header-level="3">
      <gl-accordion-item :title="__('Details')">
        <ul class="gl-p-0 gl-mb-3 gl-list-style-none gl-font-sm">
          <li v-for="key in knownStats" :key="key">
            <div class="gl-display-flex gl-w-20 gl-align-items-center">
              <gl-icon
                :size="12"
                class="gl-mr-3 gl-flex-shrink-0"
                v-bind="getStatisticIconProps(key)"
              />
              <span class="">{{ $options.STATISTIC_ITEMS[key] }}</span>
              <span class="gl-ml-auto">
                {{ stats.imported[key] || 0 }}/{{ stats.fetched[key] }}
              </span>
            </div>
          </li>
        </ul>
        <gl-link v-if="showDetails" :href="detailsPath">{{ $options.i18n.detailsLink }}</gl-link>
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
