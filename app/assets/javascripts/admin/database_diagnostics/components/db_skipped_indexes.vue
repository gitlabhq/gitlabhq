<script>
import { GlIcon, GlBadge, GlTableLite, GlLink } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';

export default {
  name: 'DbSkippedIndexes',
  components: { GlIcon, GlBadge, GlTableLite, GlLink, NumberToHumanSize },
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
  <section v-if="hasSkippedIndexes" class="gl-mt-8" data-testid="skipped-indexes-section">
    <h4 class="gl-heading-5 gl-flex gl-items-center gl-gap-3">
      <gl-icon name="information-o" variant="info" />
      {{ __('Skipped indexes') }}
      <gl-badge>
        {{ skippedIndexes.length }}
      </gl-badge>
    </h4>
    <p class="gl-text-sm gl-text-subtle" data-testid="skipped-indexes-info">
      {{ __('To avoid long-running queries, large tables were skipped.') }}
      <gl-link variant="inline" target="_blank" :href="collationCheckerHelpPath">
        {{ __('How can I check them?') }}
      </gl-link>
    </p>

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
