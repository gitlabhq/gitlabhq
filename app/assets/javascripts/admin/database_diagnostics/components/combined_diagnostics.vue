<script>
import CollationCheckerApp from './collation_checker_app.vue';
import SchemaCheckerApp from './schema_checker_app.vue';

export default {
  name: 'CombinedDiagnostics',
  components: {
    CollationCheckerApp,
    SchemaCheckerApp,
  },
};
</script>

<template>
  <section>
    <section class="gl-mb-8">
      <collation-checker-app />
    </section>

    <section class="gl-mb-8">
      <schema-checker-app />
    </section>
  </section>
</template>
