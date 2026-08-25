<script>
import { GlCard, GlIcon, GlTableLite } from '@gitlab/ui';
import { s__ } from '~/locale';
import { approximateDuration } from '~/lib/utils/datetime_utility';

export default {
  name: 'LfkBacklogResults',
  components: { GlCard, GlIcon, GlTableLite },
  props: {
    connectionName: {
      type: String,
      required: true,
    },
    backlog: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasBacklog() {
      return Boolean(this.backlog.length);
    },
    iconAttrs() {
      return {
        name: this.hasBacklog ? 'warning' : 'check-circle-filled',
        variant: this.hasBacklog ? 'warning' : 'success',
        'data-testid': 'lfk-backlog-icon',
      };
    },
  },
  methods: {
    formattedAge(seconds) {
      return approximateDuration(seconds);
    },
  },
  fields: [
    { key: 'parent_table', label: s__('DatabaseDiagnostics|Parent table') },
    { key: 'pending_records', label: s__('DatabaseDiagnostics|Pending records') },
    { key: 'oldest_pending_age_seconds', label: s__('DatabaseDiagnostics|Oldest pending') },
    { key: 'deferred_records', label: s__('DatabaseDiagnostics|Deferred') },
  ],
};
</script>

<template>
  <gl-card class="gl-mb-4" data-testid="lfk-backlog-connection-card">
    <template #header>
      <h3 class="gl-flex gl-items-center gl-gap-3">
        <gl-icon v-bind="iconAttrs" />
        {{ connectionName }}
      </h3>
    </template>

    <gl-table-lite
      v-if="hasBacklog"
      :items="backlog"
      :fields="$options.fields"
      stacked="md"
      data-testid="lfk-backlog-table"
    >
      <template #cell(pending_records)="{ item, value }">
        {{ value }}<span v-if="item.capped" data-testid="pending-capped">+</span>
      </template>

      <template #cell(oldest_pending_age_seconds)="{ value }">
        {{ formattedAge(value) }}
      </template>
    </gl-table-lite>

    <p v-else class="gl-m-0 gl-text-sm gl-text-subtle" data-testid="lfk-no-backlog">
      {{ s__('DatabaseDiagnostics|No pending cleanup backlog detected.') }}
    </p>
  </gl-card>
</template>
