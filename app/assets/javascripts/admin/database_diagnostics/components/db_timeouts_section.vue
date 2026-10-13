<script>
import { GlLink, GlTableLite } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import DiagnosticsSection from './diagnostics_section.vue';

// Gitlab::Database::Diagnostics::Checks::Timeouts::UNLIMITED.
const UNLIMITED = 0;

const TIMEOUTS_DOCS_URL = helpPagePath('administration/postgresql/tune', {
  anchor: 'required-settings-for-external-instances',
});

export default {
  name: 'DbTimeoutsSection',
  components: { GlLink, GlTableLite, DiagnosticsSection },
  props: {
    timeouts: {
      type: Object,
      required: true,
    },
  },
  computed: {
    findings() {
      return this.timeouts.findings || [];
    },
    settings() {
      return this.timeouts.settings || {};
    },
    overrides() {
      return this.timeouts.overrides || [];
    },
    hasSettings() {
      return Object.keys(this.settings).length > 0;
    },
    // Settings arrive in reading order, so no ordering is applied here.
    settingRows() {
      return Object.entries(this.settings).map(([name, setting]) => ({
        name,
        session: this.formatValue(setting.value, setting.unit),
        clusterDefault: this.formatValue(setting.default_value, setting.unit),
        source: this.formatSource(setting),
      }));
    },
    overrideRows() {
      return this.overrides.map((override) => ({
        role: override.role_name || this.$options.i18n.all,
        database: override.database_name || this.$options.i18n.all,
        name: override.name,
        value: override.value,
      }));
    },
  },
  methods: {
    formatValue(value, unit) {
      if (value === UNLIMITED) return this.$options.i18n.unlimited;

      return unit ? `${value} ${unit}` : String(value);
    },
    formatSource(setting) {
      if (!setting.source_location) return setting.source;

      return sprintf(this.$options.i18n.sourceWithLocation, {
        source: setting.source,
        location: setting.source_location,
      });
    },
  },
  settingFields: [
    { key: 'name', label: s__('DatabaseDiagnostics|Setting') },
    { key: 'session', label: s__('DatabaseDiagnostics|Session') },
    { key: 'clusterDefault', label: s__('DatabaseDiagnostics|Cluster default') },
    { key: 'source', label: s__('DatabaseDiagnostics|Source') },
  ],
  overrideFields: [
    { key: 'role', label: s__('DatabaseDiagnostics|Role') },
    { key: 'database', label: s__('DatabaseDiagnostics|Database') },
    { key: 'name', label: s__('DatabaseDiagnostics|Setting') },
    { key: 'value', label: s__('DatabaseDiagnostics|Value') },
  ],
  timeoutsDocsUrl: TIMEOUTS_DOCS_URL,
  i18n: {
    title: s__('DatabaseDiagnostics|Timeouts'),
    learnMore: s__('DatabaseDiagnostics|Learn more about recommended PostgreSQL timeout settings.'),
    overridesTitle: s__('DatabaseDiagnostics|Role and database defaults'),
    empty: s__('DatabaseDiagnostics|No timeout settings could be read.'),
    unlimited: s__('DatabaseDiagnostics|unlimited'),
    all: s__('DatabaseDiagnostics|All'),
    sourceWithLocation: s__('DatabaseDiagnostics|%{source} (%{location})'),
    sessionDescription: s__(
      'DatabaseDiagnostics|Session is the value on the connection GitLab uses. Cluster default is the value every other session gets.',
    ),
  },
};
</script>

<template>
  <section>
    <diagnostics-section
      :title="$options.i18n.title"
      :severity="timeouts.severity"
      :findings="findings"
      :foldable="hasSettings"
      testid-prefix="timeouts"
    >
      <p class="gl-text-sm gl-text-subtle">{{ $options.i18n.sessionDescription }}</p>

      <gl-table-lite
        :items="settingRows"
        :fields="$options.settingFields"
        stacked="md"
        data-testid="timeouts-settings-table"
      >
        <template #cell(name)="{ item }">
          <code>{{ item.name }}</code>
        </template>
      </gl-table-lite>

      <template v-if="overrideRows.length">
        <h5 class="gl-heading-5 gl-mt-5">{{ $options.i18n.overridesTitle }}</h5>

        <gl-table-lite
          :items="overrideRows"
          :fields="$options.overrideFields"
          stacked="md"
          data-testid="timeouts-overrides-table"
        >
          <template #cell(name)="{ item }">
            <code>{{ item.name }}</code>
          </template>
        </gl-table-lite>
      </template>

      <p class="gl-mt-3 gl-text-sm">
        <gl-link :href="$options.timeoutsDocsUrl" target="_blank">{{
          $options.i18n.learnMore
        }}</gl-link>
      </p>
    </diagnostics-section>

    <p v-if="!hasSettings" class="gl-mt-3 gl-text-sm gl-text-subtle" data-testid="timeouts-empty">
      {{ $options.i18n.empty }}
    </p>
  </section>
</template>
