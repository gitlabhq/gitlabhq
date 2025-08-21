<script>
import { GlAlert, GlIcon, GlBadge, GlTableLite } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import { __ } from '~/locale';

export default {
  name: 'DbSkippedIndexes',
  components: { GlAlert, GlIcon, GlBadge, GlTableLite, NumberToHumanSize },
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
  },
};
</script>

<template>
  <section v-if="hasSkippedIndexes" data-testid="skipped-indexes-section">
    <div class="gl-mb-4 gl-flex gl-items-center gl-gap-3">
      <gl-icon name="information-o" variant="info" data-testid="skipped-indexes-icon" />
      <h3 class="gl-m-0 gl-text-lg">
        {{ __('Skipped indexes') }}
      </h3>
      <gl-badge variant="info" data-testid="skipped-count-badge">
        {{ skippedIndexes.length }}
      </gl-badge>
    </div>

    <gl-alert variant="info" :dismissible="false" data-testid="skipped-indexes-alert">
      {{ __('Large table corruption checks skipped. Manual checking recommended.') }}
    </gl-alert>

    <gl-table-lite
      :items="skippedIndexes"
      :fields="$options.skippedIndexesFields"
      class="gl-mt-3"
      data-testid="skipped-indexes-table"
    >
      <template #cell(table_size)="{ item }">
        <number-to-human-size :value="item.table_size_bytes" />
      </template>
      <template #cell(threshold)="{ item }">
        <number-to-human-size :value="item.table_size_threshold" />
      </template>
    </gl-table-lite>
  </section>
</template>
