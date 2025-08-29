<script>
import { GlAlert, GlIcon, GlBadge, GlTableLite, GlLink } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';

export default {
  name: 'DbSkippedIndexes',
  components: { GlAlert, GlIcon, GlBadge, GlTableLite, GlLink, NumberToHumanSize },
  skippedIndexesFields: [
    { key: 'table_name', label: __('Table') },
    { key: 'index_name', label: __('Index name') },
    { key: 'table_size', label: __('Table size') },
    { key: 'threshold', label: __('Size limit') },
  ],
  props: {
    skippedIndexes: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    hasSkippedIndexes() {
      return this.skippedIndexes.length > 0;
    },
    collationCheckerHelpPath() {
      return helpPagePath('administration/raketasks/maintenance', {
        anchor: 'adjust-table-size-limits',
      });
    },
  },
};
</script>

<template>
  <section v-if="hasSkippedIndexes" data-testid="skipped-indexes-section">
    <div class="gl-mb-4 gl-flex gl-items-center gl-gap-3">
      <gl-icon name="information-o" variant="info" />
      <h3 class="gl-m-0 gl-text-lg">
        {{ __('Skipped indexes') }}
      </h3>
      <gl-badge variant="info">
        {{ skippedIndexes.length }}
      </gl-badge>
    </div>

    <gl-alert variant="info" :dismissible="false">
      <p class="gl-mb-2">
        {{
          __(
            'Large table corruption checks were skipped to avoid long-running queries. Administrators can manually check them with a higher table size limit.',
          )
        }}
      </p>

      <gl-link :href="collationCheckerHelpPath">
        {{ __('Learn how to run the check with higher limits') }}
        <gl-icon name="external-link" :size="12" />
      </gl-link>
    </gl-alert>

    <gl-table-lite :items="skippedIndexes" :fields="$options.skippedIndexesFields" class="gl-mt-3">
      <template #cell(table_size)="{ item }">
        <number-to-human-size :value="item.table_size_bytes" />
      </template>
      <template #cell(threshold)="{ item }">
        <number-to-human-size :value="item.table_size_threshold" />
      </template>
    </gl-table-lite>
  </section>
</template>
