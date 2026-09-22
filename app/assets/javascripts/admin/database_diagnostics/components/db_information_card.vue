<script>
import { GlAlert, GlCard, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import DbSchemasSection from './db_schemas_section.vue';
import DbTimeoutsSection from './db_timeouts_section.vue';
import DiagnosticsSection from './diagnostics_section.vue';

export default {
  name: 'DbInformationCard',
  components: {
    GlAlert,
    GlCard,
    GlSprintf,
    DbSchemasSection,
    DbTimeoutsSection,
    DiagnosticsSection,
  },
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
  computed: {
    findings() {
      return this.payload.findings || [];
    },
  },
  i18n: {
    header: s__('DatabaseDiagnostics|Database: %{name}'),
    searchPath: s__('DatabaseDiagnostics|Search path'),
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
        <diagnostics-section
          :title="$options.i18n.searchPath"
          :severity="payload.severity"
          :findings="findings"
          testid-prefix="search-path"
        >
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
        </diagnostics-section>

        <db-timeouts-section v-if="payload.timeouts" :timeouts="payload.timeouts" class="gl-mt-5" />

        <db-schemas-section :schemas="payload.schemas" class="gl-mt-5" />
      </template>
    </gl-card>
  </div>
</template>
