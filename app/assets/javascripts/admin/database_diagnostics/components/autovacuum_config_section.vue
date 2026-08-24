<script>
import {
  GlBadge,
  GlButton,
  GlCollapse,
  GlIcon,
  GlLink,
  GlTableLite,
  GlTooltipDirective,
} from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

// Thresholds for flagging risky autovacuum configuration. Worker counts are
// only flagged below the PostgreSQL default of 3, since most instances run
// with the default and warning on it would be noise.
const MAX_WORKERS_WARN_THRESHOLD = 3;
const DEFAULT_COST_LIMIT = 200;

const WRAPAROUND_DOCS_URL = helpPagePath('administration/troubleshooting/postgresql', {
  anchor: 'database-is-not-accepting-commands-to-avoid-wraparound-data-loss',
});

export default {
  name: 'AutovacuumConfigSection',
  components: { GlBadge, GlButton, GlCollapse, GlIcon, GlLink, GlTableLite },
  directives: { GlTooltip: GlTooltipDirective },
  props: {
    config: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      settingsExpanded: false,
      settingsDetailsId: uniqueId('autovacuum-settings-details-'),
    };
  },
  computed: {
    settings() {
      return this.config.settings || {};
    },
    hasSettings() {
      return Object.keys(this.settings).length > 0;
    },
    // Settings are already in the desired reading order and filtered to known
    // GUCs by the backend (see AUTOVACUUM_SETTING_NAMES in database_information.rb).
    settingRows() {
      return Object.keys(this.settings).map((name) => ({
        name,
        value: this.displayValue(name),
        warning: this.settingWarning(name),
      }));
    },
    flaggedSettings() {
      return this.settingRows.filter((row) => row.warning);
    },
    // null when every surfaced setting is healthy; otherwise the worst severity
    // among them, so the folded header can summarise the state at a glance.
    highestSeverity() {
      if (this.flaggedSettings.some((row) => row.warning.variant === 'danger')) return 'error';
      if (this.flaggedSettings.length) return 'warning';
      return null;
    },
    // Green tick when nothing is flagged, mirroring the search path panel.
    statusIcon() {
      if (this.highestSeverity === 'error') return { name: 'error', variant: 'danger' };
      if (this.highestSeverity === 'warning') return { name: 'warning', variant: 'warning' };
      return { name: 'check-circle-filled', variant: 'success' };
    },
    badgeVariant() {
      return this.highestSeverity === 'error' ? 'danger' : 'warning';
    },
  },
  methods: {
    rawValue(name) {
      return this.settings[name]?.value;
    },
    numericValue(name) {
      return Number(this.rawValue(name));
    },
    displayValue(name) {
      const { value, unit } = this.settings[name];

      // Show the resolved cost limit next to the -1 sentinel so the value cell
      // matches the status badge, which is computed from the effective limit.
      if (name === 'autovacuum_vacuum_cost_limit' && value === '-1') {
        const effective = this.effectiveCostLimit();

        if (Number.isFinite(effective)) {
          return sprintf(this.$options.i18n.effectiveValue, { value, effective });
        }
      }

      // -1 is PostgreSQL's "not set" sentinel (e.g. autovacuum_work_mem), so
      // appending the unit would render a confusing "-1 kB".
      return unit && value !== '-1' ? `${value} ${unit}` : value;
    },
    // autovacuum_vacuum_cost_limit = -1 means "inherit vacuum_cost_limit", so
    // resolve it before judging whether the effective limit is near the default.
    effectiveCostLimit() {
      const limit = this.numericValue('autovacuum_vacuum_cost_limit');

      return limit === -1 ? this.numericValue('vacuum_cost_limit') : limit;
    },
    settingWarning(name) {
      const { i18n } = this.$options;

      switch (name) {
        case 'autovacuum':
          return this.rawValue(name) === 'off'
            ? { variant: 'danger', label: i18n.disabled, hint: i18n.autovacuumOffHint }
            : null;
        case 'autovacuum_vacuum_cost_delay':
          return this.numericValue(name) === 0
            ? { variant: 'danger', label: i18n.throttlingOff, hint: i18n.costDelayZeroHint }
            : null;
        case 'autovacuum_max_workers':
          return this.numericValue(name) < MAX_WORKERS_WARN_THRESHOLD
            ? { variant: 'warning', label: i18n.low, hint: i18n.maxWorkersHint }
            : null;
        case 'autovacuum_vacuum_cost_limit':
          return this.effectiveCostLimit() <= DEFAULT_COST_LIMIT
            ? { variant: 'warning', label: i18n.low, hint: i18n.costLimitHint }
            : null;
        case 'autovacuum_work_mem':
          return this.rawValue(name) === '-1'
            ? { variant: 'warning', label: i18n.inherited, hint: i18n.workMemHint }
            : null;
        default:
          return null;
      }
    },
    toggleSettings() {
      this.settingsExpanded = !this.settingsExpanded;
    },
  },
  settingFields: [
    { key: 'setting', label: s__('DatabaseDiagnostics|Setting') },
    { key: 'value', label: s__('DatabaseDiagnostics|Value') },
    { key: 'status', label: s__('DatabaseDiagnostics|Status') },
  ],
  wraparoundDocsUrl: WRAPAROUND_DOCS_URL,
  i18n: {
    settingsTitle: s__('DatabaseDiagnostics|Effective settings'),
    effectiveValue: s__('DatabaseDiagnostics|%{value} (effective: %{effective})'),
    details: s__('DatabaseDiagnostics|Details'),
    settingsEmpty: s__('DatabaseDiagnostics|No autovacuum settings could be read.'),
    learnMore: s__(
      'DatabaseDiagnostics|Learn more about PostgreSQL autovacuum and transaction ID wraparound.',
    ),
    ok: s__('DatabaseDiagnostics|OK'),
    disabled: s__('DatabaseDiagnostics|Disabled'),
    throttlingOff: s__('DatabaseDiagnostics|Throttling disabled'),
    low: s__('DatabaseDiagnostics|Low'),
    inherited: s__('DatabaseDiagnostics|Inherited'),
    autovacuumOffHint: s__(
      'DatabaseDiagnostics|Autovacuum is disabled. Dead tuples will not be reclaimed automatically, risking bloat and eventually transaction ID wraparound.',
    ),
    costDelayZeroHint: s__(
      'DatabaseDiagnostics|A cost delay of zero disables throttling, so autovacuum runs at full speed and can cause write storms and replication lag.',
    ),
    maxWorkersHint: s__(
      'DatabaseDiagnostics|Only a few autovacuum workers are configured, which may be too few for a large or decomposed database fleet.',
    ),
    costLimitHint: s__(
      'DatabaseDiagnostics|The cost limit is at or near the conservative default, which is likely too low to keep up on modern storage.',
    ),
    workMemHint: s__(
      'DatabaseDiagnostics|The autovacuum_work_mem setting is unset and inherits maintenance_work_mem. Consider setting it explicitly to bound per-worker memory.',
    ),
  },
};
</script>

<template>
  <section>
    <!-- Foldable "Effective settings" row: status icon summarises health while collapsed. -->
    <div class="gl-flex gl-items-center gl-justify-between gl-rounded-base gl-bg-subtle gl-p-3">
      <div class="gl-flex gl-items-center gl-gap-2">
        <gl-icon v-if="hasSettings" v-bind="statusIcon" data-testid="settings-status-icon" />
        <h4 class="gl-heading-5 !gl-mb-0">{{ $options.i18n.settingsTitle }}</h4>
        <gl-badge
          v-if="flaggedSettings.length"
          :variant="badgeVariant"
          data-testid="settings-flagged-count"
        >
          {{ flaggedSettings.length }}
        </gl-badge>
      </div>

      <gl-button
        v-if="hasSettings"
        category="tertiary"
        size="small"
        data-testid="settings-toggle"
        :icon="settingsExpanded ? 'chevron-up' : 'chevron-down'"
        :aria-expanded="settingsExpanded.toString()"
        :aria-controls="settingsDetailsId"
        @click="toggleSettings"
      >
        {{ $options.i18n.details }}
      </gl-button>
    </div>

    <p v-if="!hasSettings" class="gl-mt-3 gl-text-sm gl-text-subtle" data-testid="settings-empty">
      {{ $options.i18n.settingsEmpty }}
    </p>

    <gl-collapse
      v-else
      :id="settingsDetailsId"
      :visible="settingsExpanded"
      class="gl-mt-3"
      data-testid="settings-details"
    >
      <gl-table-lite :items="settingRows" :fields="$options.settingFields" stacked="md">
        <template #cell(setting)="{ item }">
          <code>{{ item.name }}</code>
        </template>

        <template #cell(value)="{ item }">{{ item.value }}</template>

        <template #cell(status)="{ item }">
          <gl-badge
            v-if="item.warning"
            v-gl-tooltip
            :variant="item.warning.variant"
            icon="warning"
            :title="item.warning.hint"
            :data-testid="`status-${item.name}`"
          >
            {{ item.warning.label }}
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
    </gl-collapse>
  </section>
</template>
