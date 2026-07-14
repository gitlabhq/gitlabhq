<script>
import { GlAlert, GlBadge, GlFormGroup, GlFormSelect, GlTableLite } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/alert';
import { s__, sprintf } from '~/locale';

const SCHEMA_FIELD_NAME = 'application_setting[logging_field_schema_version]';
const DUAL_EMIT_FIELD_NAME = 'application_setting[logging_field_dual_emit_target]';
const ALERT_CONTAINER_SELECTOR = '#js-logging-field-settings';

export default {
  name: 'LoggingFieldSettings',
  components: {
    GlAlert,
    GlBadge,
    GlFormGroup,
    GlFormSelect,
    GlTableLite,
  },
  props: {
    persistedVersion: {
      type: Number,
      required: true,
    },
    persistedDualEmitTarget: {
      type: Number,
      required: false,
      default: null,
    },
    latestVersion: {
      type: Number,
      required: true,
    },
    availableVersions: {
      type: Array,
      required: true,
    },
    fieldChanges: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      schemaVersion: this.persistedVersion,
      dualEmitTarget: this.persistedDualEmitTarget ?? '',
    };
  },
  computed: {
    schemaOptions() {
      return this.availableVersions.map((v) => ({
        value: v,
        text: this.versionLabel(v),
        disabled: v < this.persistedVersion,
      }));
    },
    dualEmitOptions() {
      return [
        { value: '', text: this.$options.i18n.dualEmitNone },
        ...this.availableVersions
          .filter((v) => v > this.schemaVersion)
          .map((v) => ({ value: v, text: this.versionLabel(v) })),
      ];
    },
    isAtLatestVersion() {
      return this.schemaVersion === this.latestVersion;
    },
    helpTargetVersion() {
      if (this.dualEmitTarget !== '' && this.dualEmitTarget !== null) {
        return Number(this.dualEmitTarget);
      }
      return this.schemaVersion;
    },
    helpChanges() {
      return this.fieldChanges[String(this.helpTargetVersion)] || [];
    },
    isDualEmitting() {
      return this.dualEmitTarget !== '' && this.dualEmitTarget !== null;
    },
    showHelp() {
      return this.helpChanges.length > 0;
    },
    helpHeading() {
      if (this.isDualEmitting) {
        return sprintf(this.$options.i18n.helpHeadingDualEmit, {
          target: this.helpTargetVersion,
        });
      }
      return sprintf(this.$options.i18n.helpHeadingUpgrade, {
        target: this.helpTargetVersion,
      });
    },
    deprecatedHeader() {
      return this.isDualEmitting
        ? this.$options.i18n.deprecatedHeaderDualEmit
        : this.$options.i18n.deprecatedHeaderUpgrade;
    },
    helpFields() {
      return [
        {
          key: 'standard_field',
          label: this.$options.i18n.standardHeader,
          tdClass: 'gl-py-1 gl-pr-4 gl-font-monospace',
        },
        {
          key: 'deprecated_fields',
          label: this.deprecatedHeader,
          tdClass: 'gl-py-1 gl-font-monospace gl-text-subtle',
        },
      ];
    },
    helpNote() {
      if (this.isDualEmitting) return this.$options.i18n.helpNoteDualEmit;
      if (this.schemaVersion > 0) return this.$options.i18n.helpNoteUpgrade;
      return null;
    },
  },
  watch: {
    schemaVersion(newValue, oldValue) {
      if (this.isDualEmitting && Number(this.dualEmitTarget) <= newValue) {
        this.dualEmitTarget = '';
      }

      if (newValue === this.latestVersion && oldValue !== this.latestVersion) {
        createAlert({
          message: this.$options.i18n.latestVersionInfo,
          variant: VARIANT_INFO,
          containerSelector: ALERT_CONTAINER_SELECTOR,
        });
      }
    },
  },
  methods: {
    versionLabel(version) {
      if (version === this.latestVersion) {
        return sprintf(this.$options.i18n.versionLabelLatest, { version });
      }
      return sprintf(this.$options.i18n.versionLabel, { version });
    },
    deprecatedFieldsText(fields) {
      return fields.length > 0 ? fields.join(', ') : '—';
    },
  },
  schemaFieldName: SCHEMA_FIELD_NAME,
  dualEmitFieldName: DUAL_EMIT_FIELD_NAME,
  i18n: {
    currentVersion: s__('AdminSettings|Current version'),
    schemaVersionLabel: s__('AdminSettings|Schema version'),
    dualEmitLabel: s__('AdminSettings|Dual-emit target version'),
    dualEmitDescription: s__(
      'AdminSettings|Emit this version alongside the schema version. Must be strictly greater than the schema version.',
    ),
    dualEmitWarning: s__(
      'AdminSettings|Enabling dual-emit can significantly increase logging costs. Every dual-emitted field is written twice on each request, which roughly doubles log volume for affected fields. Use only as long as needed to validate a schema migration, then disable.',
    ),
    dualEmitNone: s__('AdminSettings|None (disabled)'),
    versionLabel: s__('AdminSettings|v%{version}'),
    versionLabelLatest: s__('AdminSettings|v%{version} (latest)'),
    latestVersionInfo: s__(
      'AdminSettings|You are on the latest available version. Dual-emit is not available.',
    ),
    helpHeadingDualEmit: s__(
      'AdminSettings|When dual-emitting v%{target}, the following fields will be emitted under both old and new names:',
    ),
    helpHeadingUpgrade: s__(
      'AdminSettings|When upgrading to v%{target}, the following field names will change:',
    ),
    standardHeader: s__('AdminSettings|Standard field name'),
    deprecatedHeaderDualEmit: s__('AdminSettings|Also emitted as (deprecated)'),
    deprecatedHeaderUpgrade: s__('AdminSettings|Replaces (deprecated)'),
    helpNoteDualEmit: s__(
      'AdminSettings|During dual-emit, both the standard and deprecated field names appear in every log line. Disable dual-emit to stop emitting deprecated names.',
    ),
    helpNoteUpgrade: s__(
      'AdminSettings|After upgrading, only the standard field names will be emitted. Enable dual-emit first if you need a transition period.',
    ),
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-4">
      <p class="gl-mb-2 gl-font-bold">{{ $options.i18n.currentVersion }}</p>
      <gl-badge variant="info" data-testid="current-version-badge">
        {{ versionLabel(persistedVersion) }}
      </gl-badge>
    </div>

    <gl-form-group
      :label="$options.i18n.schemaVersionLabel"
      label-for="logging-field-schema-version"
      label-class="label-bold"
    >
      <input :name="$options.schemaFieldName" type="hidden" :value="schemaVersion" />
      <gl-form-select
        id="logging-field-schema-version"
        v-model="schemaVersion"
        :options="schemaOptions"
        data-testid="schema-version-select"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.dualEmitLabel"
      :description="$options.i18n.dualEmitDescription"
      label-for="logging-field-dual-emit-target"
      label-class="label-bold"
    >
      <gl-alert
        variant="warning"
        :dismissible="false"
        class="gl-mb-3"
        data-testid="dual-emit-warning"
      >
        {{ $options.i18n.dualEmitWarning }}
      </gl-alert>
      <input :name="$options.dualEmitFieldName" type="hidden" :value="dualEmitTarget" />
      <gl-form-select
        id="logging-field-dual-emit-target"
        v-model="dualEmitTarget"
        :options="dualEmitOptions"
        :disabled="isAtLatestVersion"
        data-testid="dual-emit-select"
      />
    </gl-form-group>

    <div
      v-if="showHelp"
      class="gl-border gl-mb-4 gl-mt-4 gl-rounded-base gl-bg-subtle gl-p-4"
      data-testid="field-changes-help"
    >
      <p class="gl-mb-3 gl-font-bold">{{ helpHeading }}</p>
      <gl-table-lite :items="helpChanges" :fields="helpFields">
        <template #cell(deprecated_fields)="{ item }">
          {{ deprecatedFieldsText(item.deprecated_fields) }}
        </template>
      </gl-table-lite>
      <p v-if="helpNote" class="gl-mb-0 gl-mt-3 gl-text-subtle">{{ helpNote }}</p>
    </div>
  </div>
</template>
