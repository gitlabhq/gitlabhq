<script>
import { s__ } from '~/locale';
import DbInformationCard from './db_information_card.vue';

export default {
  name: 'DatabaseInformationApp',
  components: { DbInformationCard },
  inject: ['databaseInformation'],
  computed: {
    databases() {
      return Object.entries(this.databaseInformation.databases).map(([name, payload]) => ({
        name,
        payload,
      }));
    },
  },
  i18n: {
    title: s__('DatabaseDiagnostics|Database information'),
    description: s__(
      'DatabaseDiagnostics|PostgreSQL configuration and metadata for each database connection.',
    ),
  },
};
</script>

<template>
  <section>
    <h2 data-testid="title">{{ $options.i18n.title }}</h2>
    <p>{{ $options.i18n.description }}</p>

    <db-information-card
      v-for="database in databases"
      :key="database.name"
      :db-name="database.name"
      :payload="database.payload"
    />
  </section>
</template>
