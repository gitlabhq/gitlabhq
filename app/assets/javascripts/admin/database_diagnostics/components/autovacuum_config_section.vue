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

const SEVERITY_VARIANTS = {
  error: 'danger',
  warning: 'warning',
};

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
    findings() {
      return this.config.findings || [];
    },
    findingsBySetting() {
      return Object.fromEntries(this.findings.map((finding) => [finding.setting_name, finding]));
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
    statusIcon() {
      if (this.config.severity === 'error') return { name: 'error', variant: 'danger' };
      if (this.config.severity === 'warning') return { name: 'warning', variant: 'warning' };
      return { name: 'check-circle-filled', variant: 'success' };
    },
    badgeVariant() {
      return this.config.severity === 'error' ? 'danger' : 'warning';
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
    findingVariant(finding) {
      return SEVERITY_VARIANTS[finding.severity] || 'warning';
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
    details: s__('DatabaseDiagnostics|Details'),
    settingsEmpty: s__('DatabaseDiagnostics|No autovacuum settings could be read.'),
    learnMore: s__(
      'DatabaseDiagnostics|Learn more about PostgreSQL autovacuum and transaction ID wraparound.',
    ),
    ok: s__('DatabaseDiagnostics|OK'),
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
          v-if="findings.length"
          :variant="badgeVariant"
          data-testid="settings-flagged-count"
        >
          {{ findings.length }}
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
            v-if="item.finding"
            v-gl-tooltip
            :variant="findingVariant(item.finding)"
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
    </gl-collapse>
  </section>
</template>
