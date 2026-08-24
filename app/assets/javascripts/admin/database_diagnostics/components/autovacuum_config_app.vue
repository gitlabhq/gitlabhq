<script>
import { GlCard, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import AutovacuumConfigSection from './autovacuum_config_section.vue';

export default {
  name: 'AutovacuumConfigApp',
  components: { GlCard, GlSprintf, AutovacuumConfigSection },
  inject: ['databaseInformation'],
  computed: {
    databases() {
      return Object.entries(this.databaseInformation.databases).map(([name, payload]) => ({
        name,
        config: payload.autovacuum_config || {},
      }));
    },
  },
  i18n: {
    title: s__('DatabaseDiagnostics|Autovacuum configuration'),
    description: s__(
      'DatabaseDiagnostics|Effective autovacuum settings and per-table overrides for each database connection, with known-risky values flagged.',
    ),
    header: s__('DatabaseDiagnostics|Database: %{name}'),
  },
};
</script>

<template>
  <section>
    <h2>{{ $options.i18n.title }}</h2>
    <p>{{ $options.i18n.description }}</p>

    <gl-card
      v-for="database in databases"
      :key="database.name"
      class="gl-mb-6 gl-w-full"
      :data-testid="`autovacuum-config-${database.name}`"
    >
      <template #header>
        <h3 class="gl-heading-5 !gl-mb-0">
          <gl-sprintf :message="$options.i18n.header">
            <template #name>{{ database.name }}</template>
          </gl-sprintf>
        </h3>
      </template>

      <autovacuum-config-section class="gl-mt-5" :config="database.config" />
    </gl-card>
  </section>
</template>
