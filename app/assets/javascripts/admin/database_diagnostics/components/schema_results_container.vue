<script>
import { GlCard, GlSprintf } from '@gitlab/ui';
import SchemaIssuesSection from './schema_issues_section.vue';

export default {
  name: 'SchemaResultsContainer',
  components: { GlCard, GlSprintf, SchemaIssuesSection },
  props: {
    schemaDiagnostics: {
      type: Object,
      required: true,
    },
  },
  computed: {
    databases() {
      return Object.entries(this.schemaDiagnostics.schema_check_results).map(
        ([dbName, dbResults]) => ({
          name: dbName,
          results: dbResults,
        }),
      );
    },
  },
};
</script>

<template>
  <section>
    <div
      v-for="database in databases"
      :key="database.name"
      class="gl-mb-6"
      :data-testid="`database-${database.name}`"
    >
      <gl-card class="gl-w-full">
        <template #header>
          <span class="gl-font-bold">
            <gl-sprintf :message="s__('DatabaseDiagnostics|Database: %{name}')">
              <template #name>
                {{ database.name }}
              </template>
            </gl-sprintf>
          </span>
        </template>

        <schema-issues-section :database-results="database.results" />
      </gl-card>
    </div>
  </section>
</template>
