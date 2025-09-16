<script>
import { GlCard, GlSprintf } from '@gitlab/ui';
import DbCollationMismatches from './db_collation_mismatches.vue';
import DbCorruptedIndexes from './db_corrupted_indexes.vue';
import DbSkippedIndexes from './db_skipped_indexes.vue';

export default {
  name: 'DbDiagnosticResults',
  components: { GlCard, GlSprintf, DbCollationMismatches, DbCorruptedIndexes, DbSkippedIndexes },
  props: {
    dbName: {
      type: String,
      required: true,
    },
    dbDiagnosticResult: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <section>
    <gl-card class="gl-w-full">
      <template #header>
        <span class="gl-font-bold">
          <gl-sprintf :message="s__('DatabaseDiagnostics|Database: %{name}')">
            <template #name>
              {{ dbName }}
            </template>
          </gl-sprintf>
        </span>
      </template>

      <db-collation-mismatches :collation-mismatches="dbDiagnosticResult.collation_mismatches" />
      <db-corrupted-indexes :corrupted-indexes="dbDiagnosticResult.corrupted_indexes" />
      <db-skipped-indexes :skipped-indexes="dbDiagnosticResult.skipped_indexes" />
    </gl-card>
  </section>
</template>
