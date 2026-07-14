<script>
import { GlAlert, GlBadge, GlButton, GlCard, GlIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import DbSchemasSection from './db_schemas_section.vue';

const SEVERITY_VARIANTS = {
  error: 'danger',
  warning: 'warning',
};

const SEVERITY_ORDER = {
  error: 0,
  warning: 1,
};

export default {
  name: 'DbInformationCard',
  components: { GlAlert, GlBadge, GlButton, GlCard, GlIcon, GlSprintf, DbSchemasSection },
  props: {
    dbName: {
      type: String,
      required: true,
    },
    payload: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      expanded: false,
    };
  },
  computed: {
    findings() {
      return [...(this.payload.findings || [])].sort(
        (a, b) =>
          (SEVERITY_ORDER[a.severity] ?? Number.MAX_SAFE_INTEGER) -
          (SEVERITY_ORDER[b.severity] ?? Number.MAX_SAFE_INTEGER),
      );
    },
    highestSeverity() {
      if (this.findings.some((finding) => finding.severity === 'error')) return 'error';
      if (this.findings.some((finding) => finding.severity === 'warning')) return 'warning';
      return null;
    },
    // Green when there are no findings; otherwise reflects the worst severity.
    statusIcon() {
      if (this.highestSeverity === 'error') return { name: 'error', variant: 'danger' };
      if (this.highestSeverity === 'warning') return { name: 'warning', variant: 'warning' };
      return { name: 'check-circle-filled', variant: 'success' };
    },
    badgeVariant() {
      return this.highestSeverity === 'error' ? 'danger' : 'warning';
    },
    ariaControlsId() {
      return `search-path-details-${this.dbName}`;
    },
  },
  methods: {
    variantFor(severity) {
      return SEVERITY_VARIANTS[severity] || 'warning';
    },
    toggle() {
      this.expanded = !this.expanded;
    },
  },
  i18n: {
    header: s__('DatabaseDiagnostics|Database: %{name}'),
    searchPath: s__('DatabaseDiagnostics|Search path'),
    details: s__('DatabaseDiagnostics|Details'),
    currentUserLabel: s__('DatabaseDiagnostics|Current user:'),
    searchPathLabel: s__('DatabaseDiagnostics|Search path:'),
  },
};
</script>

<template>
  <div class="gl-mb-6" :data-testid="`database-${dbName}`">
    <gl-card class="gl-w-full">
      <template #header>
        <h3 class="gl-heading-5 !gl-mb-0">
          <gl-sprintf :message="$options.i18n.header">
            <template #name>{{ dbName }}</template>
          </gl-sprintf>
        </h3>
      </template>

      <gl-alert v-if="payload.error" variant="warning" :dismissible="false">
        {{ payload.error }}
      </gl-alert>

      <template v-else>
        <!-- Foldable "Search path" row: status icon + always-present Details toggle -->
        <div class="gl-flex gl-items-center gl-justify-between gl-rounded-base gl-bg-subtle gl-p-3">
          <div class="gl-flex gl-items-center gl-gap-2">
            <gl-icon v-bind="statusIcon" data-testid="status-icon" />
            <h4 class="gl-heading-5 !gl-mb-0">{{ $options.i18n.searchPath }}</h4>
            <gl-badge v-if="findings.length" :variant="badgeVariant" data-testid="findings-count">
              {{ findings.length }}
            </gl-badge>
          </div>

          <gl-button
            category="tertiary"
            size="small"
            data-testid="search-path-toggle"
            :icon="expanded ? 'chevron-up' : 'chevron-down'"
            :aria-expanded="expanded.toString()"
            :aria-controls="ariaControlsId"
            @click="toggle"
          >
            {{ $options.i18n.details }}
          </gl-button>
        </div>

        <div v-if="expanded" :id="ariaControlsId" class="gl-mt-3" data-testid="search-path-details">
          <p class="gl-text-sm gl-text-subtle">
            <span data-testid="current-user">
              <strong>{{ $options.i18n.currentUserLabel }}</strong>
              <code>{{ payload.current_user }}</code>
            </span>
            <span class="gl-ml-3" data-testid="search-path">
              <strong>{{ $options.i18n.searchPathLabel }}</strong>
              <code>{{ payload.search_path }}</code>
            </span>
          </p>

          <gl-alert
            v-for="(finding, index) in findings"
            :key="`${finding.code}-${index}`"
            :variant="variantFor(finding.severity)"
            :dismissible="false"
            class="gl-mb-3"
            :data-testid="`finding-${finding.code}`"
          >
            {{ finding.message }}
          </gl-alert>
        </div>

        <db-schemas-section :schemas="payload.schemas" class="gl-mt-5" />
      </template>
    </gl-card>
  </div>
</template>
