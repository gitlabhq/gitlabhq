<script>
import { GlCard, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import DbVacuumSection from './db_vacuum_section.vue';

export default {
  name: 'VacuumInformationApp',
  components: { GlCard, GlSprintf, DbVacuumSection },
  inject: ['databaseInformation'],
  computed: {
    databases() {
      return Object.entries(this.databaseInformation.databases).map(([name, payload]) => ({
        name,
        vacuums: payload.vacuums || [],
      }));
    },
  },
  i18n: {
    title: s__('DatabaseDiagnostics|Vacuum information'),
    description: s__(
      'DatabaseDiagnostics|In-progress vacuum operations for each database connection.',
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
      :data-testid="`vacuum-${database.name}`"
    >
      <template #header>
        <h3 class="gl-heading-5 !gl-mb-0">
          <gl-sprintf :message="$options.i18n.header">
            <template #name>{{ database.name }}</template>
          </gl-sprintf>
        </h3>
      </template>

      <db-vacuum-section class="gl-mt-5" :vacuums="database.vacuums" />
    </gl-card>
  </section>
</template>
