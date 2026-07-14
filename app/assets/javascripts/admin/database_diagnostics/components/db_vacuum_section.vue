<script>
import { GlBadge, GlIcon, GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { approximateDuration } from '~/lib/utils/datetime/date_calculation_utility';

const LONG_RUNNING_THRESHOLD_SECONDS = 6 * 60 * 60;

export default {
  name: 'DbVacuumSection',
  components: { GlBadge, GlIcon, GlTableLite },
  directives: { GlTooltip: GlTooltipDirective },
  props: {
    vacuums: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasActivity() {
      return this.vacuums.length > 0;
    },

    sortedVacuums() {
      return [...this.vacuums].sort((a, b) => {
        const aTime = typeof a.running_time_seconds === 'number' ? a.running_time_seconds : -1;
        const bTime = typeof b.running_time_seconds === 'number' ? b.running_time_seconds : -1;

        if (bTime !== aTime) return bTime - aTime;

        return a.table_name.localeCompare(b.table_name);
      });
    },
  },
  methods: {
    heapProgress(item) {
      if (!item.heap_blks_total) return '0%';

      return `${Math.min(100, Math.round((item.heap_blks_scanned / item.heap_blks_total) * 100))}%`;
    },
    formatBytes(bytes) {
      return numberToHumanSize(bytes);
    },
    formatDelay(milliseconds) {
      return sprintf(s__('DatabaseDiagnostics|%{milliseconds} ms'), { milliseconds });
    },
    // More than one index pass means the dead-tuple store filled before the
    // heap scan completed, i.e. maintenance_work_mem / autovacuum_work_mem is
    // too small for the workload. This is the signal worth flagging visually.
    isMemoryPressure(item) {
      return item.index_vacuum_count > 1;
    },
    vacuumTypeLabel(item) {
      return item.vacuum_type === 'autovacuum'
        ? s__('DatabaseDiagnostics|Autovacuum')
        : s__('DatabaseDiagnostics|Manual VACUUM');
    },
    formatDuration(seconds) {
      if (typeof seconds !== 'number') return this.$options.i18n.notAvailable;

      return approximateDuration(seconds);
    },
    isLongRunning(item) {
      return (
        typeof item.running_time_seconds === 'number' &&
        item.running_time_seconds > LONG_RUNNING_THRESHOLD_SECONDS
      );
    },
  },
  fields: [
    { key: 'table', label: s__('DatabaseDiagnostics|Table') },
    { key: 'type', label: s__('DatabaseDiagnostics|Type') },
    { key: 'runningTime', label: s__('DatabaseDiagnostics|Running for') },
    { key: 'phase', label: s__('DatabaseDiagnostics|Phase') },
    { key: 'heapProgress', label: s__('DatabaseDiagnostics|Heap scanned') },
    { key: 'indexProgress', label: s__('DatabaseDiagnostics|Indexes processed') },
    { key: 'deadTuples', label: s__('DatabaseDiagnostics|Dead tuples') },
    { key: 'indexVacuumCount', label: s__('DatabaseDiagnostics|Index passes') },
    { key: 'delayTime', label: s__('DatabaseDiagnostics|Delay time') },
  ],
  i18n: {
    title: s__('DatabaseDiagnostics|Vacuum activity'),
    empty: s__('DatabaseDiagnostics|No vacuum operations are currently running.'),
    memoryPressure: s__('DatabaseDiagnostics|Memory pressure'),
    memoryPressureHint: s__(
      'DatabaseDiagnostics|More than one index pass means the dead-tuple store filled up. Consider increasing maintenance_work_mem or autovacuum_work_mem.',
    ),
    notAvailable: s__('DatabaseDiagnostics|Not available'),
    antiWraparound: s__('DatabaseDiagnostics|Anti-wraparound'),
    antiWraparoundHint: s__(
      'DatabaseDiagnostics|This vacuum is preventing transaction ID wraparound. It will not auto-cancel and must not be terminated casually, as doing so risks the database forcing a shutdown to protect against data loss.',
    ),
    longRunning: s__('DatabaseDiagnostics|Long-running'),
    longRunningHint: s__(
      'DatabaseDiagnostics|This vacuum has been running for over six hours. Large tables can legitimately take this long, but a vacuum that never finishes may be blocked or starved of resources and is worth investigating.',
    ),
  },
};
</script>

<template>
  <section>
    <h4 class="gl-heading-5 gl-flex gl-items-center gl-gap-3">
      <gl-icon name="information-o" variant="info" />
      {{ $options.i18n.title }}
    </h4>

    <p v-if="!hasActivity" class="gl-text-sm gl-text-subtle" data-testid="vacuum-empty">
      {{ $options.i18n.empty }}
    </p>

    <gl-table-lite v-else :items="sortedVacuums" :fields="$options.fields" stacked="md">
      <template #cell(table)="{ item }">
        <code>{{ item.schema_name }}.{{ item.table_name }}</code>
      </template>

      <template #cell(type)="{ item }">
        <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
          <gl-badge variant="neutral">
            {{ vacuumTypeLabel(item) }}
          </gl-badge>
          <gl-badge
            v-if="item.anti_wraparound"
            v-gl-tooltip
            variant="info"
            icon="information-o"
            :title="$options.i18n.antiWraparoundHint"
            data-testid="anti-wraparound-badge"
          >
            {{ $options.i18n.antiWraparound }}
          </gl-badge>
        </div>
      </template>

      <template #cell(runningTime)="{ item }">
        <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
          <span>{{ formatDuration(item.running_time_seconds) }}</span>
          <gl-badge
            v-if="isLongRunning(item)"
            v-gl-tooltip
            variant="warning"
            icon="warning"
            :title="$options.i18n.longRunningHint"
          >
            {{ $options.i18n.longRunning }}
          </gl-badge>
        </div>
      </template>

      <template #cell(heapProgress)="{ item }">
        {{ heapProgress(item) }}
        <span class="gl-text-subtle"
          >({{ item.heap_blks_scanned }} / {{ item.heap_blks_total }})</span
        >
      </template>

      <template #cell(indexProgress)="{ item }">
        {{ item.indexes_processed }} / {{ item.indexes_total }}
      </template>

      <template #cell(deadTuples)="{ item }">
        {{ formatBytes(item.dead_tuple_bytes) }} / {{ formatBytes(item.max_dead_tuple_bytes) }}
      </template>

      <template #cell(indexVacuumCount)="{ item }">
        <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
          <span>{{ item.index_vacuum_count }}</span>
          <gl-badge
            v-if="isMemoryPressure(item)"
            v-gl-tooltip
            variant="danger"
            icon="warning"
            :title="$options.i18n.memoryPressureHint"
          >
            {{ $options.i18n.memoryPressure }}
          </gl-badge>
        </div>
      </template>

      <template #cell(delayTime)="{ item }">
        <span v-if="item.delay_time === null" class="gl-text-subtle">
          {{ $options.i18n.notAvailable }}
        </span>
        <span v-else>{{ formatDelay(item.delay_time) }}</span>
      </template>
    </gl-table-lite>
  </section>
</template>
