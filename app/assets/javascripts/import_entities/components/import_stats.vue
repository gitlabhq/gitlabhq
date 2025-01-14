<script>
import { GlAccordion, GlAccordionItem, GlIcon, GlLink } from '@gitlab/ui';

import { BULK_IMPORT_STATIC_ITEMS } from '~/import/constants';
import { STATUSES } from '../constants';

export default {
  name: 'ImportStats',

  components: {
    GlAccordion,
    GlAccordionItem,
    GlIcon,
    GlLink,
  },

  props: {
    failuresHref: {
      type: String,
      required: false,
      default: '',
    },
    stats: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    statsMapping: {
      type: Object,
      required: false,
      default: () => BULK_IMPORT_STATIC_ITEMS,
    },
    status: {
      type: String,
      required: true,
    },
  },

  methods: {
    importedByType(type) {
      return this.stats[type].imported || 0;
    },

    fetchedByType(type) {
      return this.stats[type].fetched;
    },

    statsIconProps(type) {
      const fetched = this.fetchedByType(type);
      const imported = this.importedByType(type);

      if (fetched === imported) {
        if (imported === 0) {
          return { name: 'status-scheduled', variant: 'subtle' };
        }

        return { name: 'status-success', variant: 'success' };
      }

      if (this.status === STATUSES.FINISHED) {
        return { name: 'status-alert', variant: 'warning' };
      }

      return { name: 'status-running', variant: 'info' };
    },
  },
};
</script>

<template>
  <gl-accordion :header-level="3">
    <gl-accordion-item :title="__('View details')">
      <ul class="gl-mb-3 gl-list-none gl-p-0 gl-text-sm">
        <li v-for="key in Object.keys(stats)" :key="key" data-testid="import-stat-item">
          <div class="gl-flex gl-w-28 gl-items-center">
            <gl-icon :size="12" class="gl-mr-2 gl-shrink-0" v-bind="statsIconProps(key)" />
            <span>{{ statsMapping[key] || key }}</span>
            <span class="gl-ml-auto"> {{ importedByType(key) }}/{{ fetchedByType(key) }} </span>
          </div>
        </li>
      </ul>
      <gl-link v-if="failuresHref" :href="failuresHref"
        >{{ s__('Import|Show errors') }} &gt;</gl-link
      >
    </gl-accordion-item>
  </gl-accordion>
</template>
