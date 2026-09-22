<script>
import { GlAlert, GlBadge, GlLink, GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { s__, n__, sprintf, formatNumber } from '~/locale';
import { bytes } from '~/lib/utils/unit_format';
import { helpPagePath } from '~/helpers/help_page_helper';
import { severityVariant } from '../utils';
import DiagnosticsSection from './diagnostics_section.vue';

const WRAPAROUND_DOCS_URL = helpPagePath('administration/troubleshooting/postgresql', {
  anchor: 'database-is-not-accepting-commands-to-avoid-wraparound-data-loss',
});

export default {
  name: 'AutovacuumConfigSection',
  components: { GlAlert, GlBadge, GlLink, GlTableLite, DiagnosticsSection },
  directives: { GlTooltip: GlTooltipDirective },
  props: {
    config: {
      type: Object,
      required: true,
    },
  },
  computed: {
    settings() {
      return this.config.settings || {};
    },
    findings() {
      return this.config.findings || [];
    },
    // Findings without a setting_name are table-level; the settings header
    // only summarises the per-setting ones.
    settingsFindings() {
      return this.findings.filter((finding) => finding.setting_name);
    },
    tableFindings() {
      return this.findings.filter((finding) => !finding.setting_name);
    },
    findingsBySetting() {
      return Object.fromEntries(
        this.settingsFindings.map((finding) => [finding.setting_name, finding]),
      );
    },
    tableOverrides() {
      return this.config.table_overrides || [];
    },
    hasSettings() {
      return Object.keys(this.settings).length > 0;
    },
    // Settings are already in the desired reading order and filtered to known
    // GUCs by the backend.
    settingRows() {
      return Object.keys(this.settings).map((name) => ({
        name,
        value: this.displayValue(name),
        finding: this.findingsBySetting[name],
      }));
    },
    settingsSeverity() {
      if (this.settingsFindings.some((finding) => finding.severity === 'error')) return 'error';
      if (this.settingsFindings.length) return 'warning';
      return null;
    },
    // The only adverse signal among overrides is a table with autovacuum
    // disabled; everything else is informational tuning.
    overridesSeverity() {
      return this.tableOverrides.some((table) => table.autovacuum_disabled) ? 'error' : null;
    },
    scaleFactorRisks() {
      return this.config.scale_factor_risks || [];
    },
  },
  methods: {
    displayValue(name) {
      const { value, unit, effective_value: effective } = this.settings[name];

      if (effective) {
        return sprintf(this.$options.i18n.effectiveValue, { value, effective });
      }

      // -1 is PostgreSQL's "not set" sentinel (e.g. autovacuum_work_mem), so
      // appending the unit would render a confusing "-1 kB".
      return unit && value !== '-1' ? `${value} ${unit}` : value;
    },
    findingLabel(finding) {
      return (
        this.$options.findingLabels[finding.code] ||
        this.$options.severityLabels[finding.severity] ||
        this.$options.severityLabels.warning
      );
    },
    overrideEntries(table) {
      return Object.entries(table.overrides || {}).map(([key, value]) => `${key}=${value}`);
    },
    formatBytes(value) {
      return bytes(value, 2, { unitSeparator: ' ' });
    },
    rowCount(count) {
      return sprintf(
        n__('DatabaseDiagnostics|~%{count} row', 'DatabaseDiagnostics|~%{count} rows', count),
        { count: formatNumber(count) },
      );
    },
    severityVariant,
  },
  settingFields: [
    { key: 'setting', label: s__('DatabaseDiagnostics|Setting') },
    { key: 'value', label: s__('DatabaseDiagnostics|Value') },
    { key: 'status', label: s__('DatabaseDiagnostics|Status') },
  ],
  overrideFields: [
    { key: 'table', label: s__('DatabaseDiagnostics|Table') },
    { key: 'size', label: s__('DatabaseDiagnostics|Size') },
    { key: 'overrides', label: s__('DatabaseDiagnostics|Overrides') },
  ],
  riskFields: [
    { key: 'table', label: s__('DatabaseDiagnostics|Table') },
    { key: 'size', label: s__('DatabaseDiagnostics|Size') },
  ],
  wraparoundDocsUrl: WRAPAROUND_DOCS_URL,
  // Short badge labels per backend finding code; the finding message itself is
  // shown as the tooltip.
  findingLabels: {
    autovacuum_disabled: s__('DatabaseDiagnostics|Disabled'),
    autovacuum_throttling_disabled: s__('DatabaseDiagnostics|Throttling disabled'),
    autovacuum_max_workers_low: s__('DatabaseDiagnostics|Low'),
    autovacuum_cost_limit_low: s__('DatabaseDiagnostics|Low'),
    autovacuum_work_mem_inherited: s__('DatabaseDiagnostics|Inherited'),
  },
  severityLabels: {
    error: s__('DatabaseDiagnostics|Error'),
    warning: s__('DatabaseDiagnostics|Warning'),
  },
  i18n: {
    settingsTitle: s__('DatabaseDiagnostics|Effective settings'),
    effectiveValue: s__('DatabaseDiagnostics|%{value} (effective: %{effective})'),
    settingsEmpty: s__('DatabaseDiagnostics|No autovacuum settings could be read.'),
    overridesTitle: s__('DatabaseDiagnostics|Per-table overrides'),
    scaleFactorTitle: s__('DatabaseDiagnostics|Scale factor risk'),
    learnMore: s__(
      'DatabaseDiagnostics|Learn more about PostgreSQL autovacuum and transaction ID wraparound.',
    ),
    ok: s__('DatabaseDiagnostics|OK'),
    tableDisabled: s__('DatabaseDiagnostics|Autovacuum disabled'),
    tableDisabledHint: s__(
      'DatabaseDiagnostics|Autovacuum is disabled for this table, so its dead tuples are never reclaimed automatically.',
    ),
  },
};
</script>

<template>
  <section>
    <!-- Findings are shown per setting in the table, not as alerts. -->
    <diagnostics-section
      :title="$options.i18n.settingsTitle"
      :severity="settingsSeverity"
      :findings="settingsFindings"
      :foldable="hasSettings"
      :show-finding-alerts="false"
      testid-prefix="settings"
    >
      <gl-table-lite :items="settingRows" :fields="$options.settingFields" stacked="md">
        <template #cell(setting)="{ item }">
          <code>{{ item.name }}</code>
        </template>

        <template #cell(value)="{ item }">{{ item.value }}</template>

        <template #cell(status)="{ item }">
          <gl-badge
            v-if="item.finding"
            v-gl-tooltip
            :variant="severityVariant(item.finding.severity)"
            icon="warning"
            :title="item.finding.message"
            :data-testid="`status-${item.name}`"
          >
            {{ findingLabel(item.finding) }}
          </gl-badge>
          <gl-badge v-else variant="success" :data-testid="`status-ok-${item.name}`">{{
            $options.i18n.ok
          }}</gl-badge>
        </template>
      </gl-table-lite>

      <p class="gl-mt-3 gl-text-sm">
        <gl-link :href="$options.wraparoundDocsUrl" target="_blank">{{
          $options.i18n.learnMore
        }}</gl-link>
      </p>
    </diagnostics-section>

    <p v-if="!hasSettings" class="gl-mt-3 gl-text-sm gl-text-subtle" data-testid="settings-empty">
      {{ $options.i18n.settingsEmpty }}
    </p>

    <gl-alert
      v-for="finding in tableFindings"
      :key="finding.code"
      :variant="severityVariant(finding.severity)"
      :dismissible="false"
      class="gl-mt-5"
      :data-testid="`table-finding-${finding.code}`"
    >
      {{ finding.message }}
    </gl-alert>

    <!-- Omitted entirely when no table overrides autovacuum. -->
    <diagnostics-section
      v-if="tableOverrides.length"
      :title="$options.i18n.overridesTitle"
      :severity="overridesSeverity"
      :count="tableOverrides.length"
      class="gl-mt-5"
      testid-prefix="overrides"
    >
      <gl-table-lite
        :items="tableOverrides"
        :fields="$options.overrideFields"
        stacked="md"
        data-testid="overrides-table"
      >
        <template #cell(table)="{ item }">
          <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
            <code>{{ item.schema_name }}.{{ item.table_name }}</code>
            <gl-badge
              v-if="item.autovacuum_disabled"
              v-gl-tooltip
              variant="danger"
              icon="warning"
              :title="$options.i18n.tableDisabledHint"
              data-testid="table-disabled-badge"
            >
              {{ $options.i18n.tableDisabled }}
            </gl-badge>
          </div>
        </template>

        <template #cell(size)="{ item }">
          {{ formatBytes(item.total_bytes) }}
          <span class="gl-text-subtle">({{ rowCount(item.estimated_rows) }})</span>
        </template>

        <template #cell(overrides)="{ item }">
          <code v-for="entry in overrideEntries(item)" :key="entry" class="gl-mr-2">{{
            entry
          }}</code>
        </template>
      </gl-table-lite>
    </diagnostics-section>

    <template v-if="scaleFactorRisks.length">
      <h4 class="gl-heading-5 gl-mt-5">{{ $options.i18n.scaleFactorTitle }}</h4>

      <gl-table-lite
        :items="scaleFactorRisks"
        :fields="$options.riskFields"
        stacked="md"
        data-testid="scale-factor-risks"
      >
        <template #cell(table)="{ item }">
          <code>{{ item.schema_name }}.{{ item.table_name }}</code>
        </template>

        <template #cell(size)="{ item }">
          {{ formatBytes(item.total_bytes) }}
          <span class="gl-text-subtle">({{ rowCount(item.estimated_rows) }})</span>
        </template>
      </gl-table-lite>
    </template>
  </section>
</template>
