<script>
import CollationCheckerApp from './collation_checker_app.vue';
import DatabaseInformationApp from './database_information_app.vue';
import LooseForeignKeysBacklogCheckerApp from './loose_foreign_keys_backlog_checker_app.vue';
import SchemaCheckerApp from './schema_checker_app.vue';
import VacuumInformationApp from './vacuum_information_app.vue';
import AutovacuumConfigApp from './autovacuum_config_app.vue';

export default {
  name: 'CombinedDiagnostics',
  components: {
    VacuumInformationApp,
    AutovacuumConfigApp,
    CollationCheckerApp,
    DatabaseInformationApp,
    LooseForeignKeysBacklogCheckerApp,
    SchemaCheckerApp,
  },
};
</script>

<template>
  <section>
    <section class="gl-mb-8">
      <database-information-app />
    </section>

    <vacuum-information-app class="gl-mb-8" />

    <autovacuum-config-app class="gl-mb-8" />

    <section class="gl-mb-8">
      <collation-checker-app />
    </section>

    <section class="gl-mb-8">
      <schema-checker-app />
    </section>

    <section class="gl-mb-8">
      <loose-foreign-keys-backlog-checker-app />
    </section>
  </section>
</template>
