<script>
import { GlIcon, GlBadge, GlTableLite } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import { __ } from '~/locale';

export default {
  name: 'DbCorruptedIndexes',
  components: { GlIcon, GlBadge, GlTableLite, NumberToHumanSize },
  props: {
    corruptedIndexes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasCorruptedIndexes() {
      return Boolean(this.corruptedIndexes.length);
    },
    iconAttrs() {
      return {
        name: this.hasCorruptedIndexes ? 'error' : 'check-circle-filled',
        variant: this.hasCorruptedIndexes ? 'danger' : 'success',
        'data-testid': 'corrupted-indexes-icon',
      };
    },
  },
  corruptedIndexesFields: [
    { key: 'index_name', label: __('Index name') },
    { key: 'table_name', label: __('Table') },
    { key: 'affected_columns', label: __('Affected columns') },
    { key: 'is_unique', label: __('Unique') },
    { key: 'size_bytes', label: __('Size') },
    { key: 'corruption_types', label: __('Issues') },
    { key: 'needs_deduplication', label: __('Needs deduplication') },
  ],
};
</script>

<template>
  <section class="gl-mt-8">
    <h4 class="gl-heading-5 gl-flex gl-items-center gl-gap-3">
      <gl-icon v-bind="iconAttrs" />
      {{ __('Corrupted indexes') }}
      <gl-badge v-if="hasCorruptedIndexes" data-testid="corrupted-indexes-count">
        {{ corruptedIndexes.length }}
      </gl-badge>
    </h4>

    <gl-table-lite
      v-if="hasCorruptedIndexes"
      :items="corruptedIndexes"
      :fields="$options.corruptedIndexesFields"
      stacked="lg"
      data-testid="corrupted-indexes-table"
    >
      <template #cell(is_unique)="{ value }">
        {{ value ? __('Yes') : __('No') }}
      </template>

      <template #cell(size_bytes)="{ value }">
        <number-to-human-size :value="value" />
      </template>

      <template #cell(corruption_types)="{ value }">
        <gl-badge
          v-for="type in value"
          :key="type"
          :variant="type === 'structural' ? 'danger' : 'warning'"
          class="gl-mr-2"
          :data-testid="`corruption-type-${type}`"
        >
          {{ type === 'structural' ? __('Structural') : __('Duplicates') }}
        </gl-badge>
      </template>

      <template #cell(needs_deduplication)="{ value }">
        {{ value ? __('Yes') : __('No') }}
      </template>
    </gl-table-lite>
    <template v-else>
      <p class="gl-text-sm gl-text-subtle" data-testid="no-corrupted-indexes-alert">
        {{ __('No corrupted indexes detected.') }}
      </p>
    </template>
  </section>
</template>
