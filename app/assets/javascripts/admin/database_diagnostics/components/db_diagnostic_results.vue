<script>
import { GlCard, GlSprintf } from '@gitlab/ui';
import DbCollationMismatches from './db_collation_mismatches.vue';
import DbCorruptedIndexes from './db_corrupted_indexes.vue';
import DbSkippedIndexes from './db_skipped_indexes.vue';
import DbIssuesCta from './db_issues_cta.vue';

export default {
  name: 'DbDiagnosticResults',
  components: {
    GlCard,
    GlSprintf,
    DbCollationMismatches,
    DbCorruptedIndexes,
    DbSkippedIndexes,
    DbIssuesCta,
  },
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
  computed: {
    hasIssues() {
      return this.dbDiagnosticResult.corrupted_indexes?.length > 0;
    },
  },
};
</script>

<template>
  <section>
    <gl-card class="gl-w-full">
      <template #header>
        <h3 class="gl-heading-5 !gl-mb-0">
          <gl-sprintf :message="s__('DatabaseDiagnostics|Database: %{name}')">
            <template #name>
              {{ dbName }}
            </template>
          </gl-sprintf>
        </h3>
      </template>

      <db-collation-mismatches :collation-mismatches="dbDiagnosticResult.collation_mismatches" />
      <db-corrupted-indexes :corrupted-indexes="dbDiagnosticResult.corrupted_indexes" />
      <db-skipped-indexes :skipped-indexes="dbDiagnosticResult.skipped_indexes" />

      <template v-if="hasIssues" #footer>
        <db-issues-cta />
      </template>
    </gl-card>
  </section>
</template>
