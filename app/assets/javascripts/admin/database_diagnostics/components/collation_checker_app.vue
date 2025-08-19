<script>
import { GlAlert, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { __, s__, sprintf } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import DbDiagnosticResults from './db_diagnostic_results.vue';
import DbIssuesCta from './db_issues_cta.vue';

export default {
  name: 'CollationCheckerApp',
  components: {
    GlAlert,
    GlButton,
    GlSkeletonLoader,
    DbDiagnosticResults,
    DbIssuesCta,
  },
  retryIntervalMs: 5000, // 5 seconds
  maxRetryAttempts: 60, // 5 minutes total (60 × 5 seconds)
  inject: ['runCollationCheckUrl', 'collationCheckResultsUrl'],
  data() {
    return {
      isLoading: false,
      dbDiagnostics: null,
      error: null,
      fetchRetryIds: [],
      retryAttempts: 0,
    };
  },
  computed: {
    formattedLastRunAt() {
      if (!this.dbDiagnostics?.metadata?.last_run_at) return '';

      const timestamp = localeDateFormat.asDateTime.format(
        new Date(this.dbDiagnostics.metadata.last_run_at),
      );

      return sprintf(s__('DatabaseDiagnostics|Last checked: %{timestamp}'), { timestamp });
    },
    hasDbDiagnostics() {
      return Boolean(this.dbDiagnostics?.databases);
    },
    hasIssues() {
      if (!this.dbDiagnostics?.databases) return false;

      return Object.values(this.dbDiagnostics.databases).some(
        (db) => db.corrupted_indexes?.length > 0,
      );
    },
  },
  created() {
    this.fetchDbDiagnostics();
  },
  beforeDestroy() {
    this.clearFetchRetries();
  },
  methods: {
    async fetchDbDiagnostics({ retry = false } = {}) {
      this.isLoading = true;
      this.error = null;

      try {
        const { data } = await axios.get(this.collationCheckResultsUrl);

        if (data?.databases) {
          this.dbDiagnostics = data;
        }
        this.isLoading = false;
      } catch (error) {
        if (error.response?.status === HTTP_STATUS_NOT_FOUND) {
          if (retry) {
            this.retryFetchDbDiagnostics();
          } else {
            this.isLoading = false;
          }
        } else {
          this.clearFetchRetries();
          this.error =
            error.response?.data?.error ?? __('An error occurred while fetching results');
        }
      }
    },
    retryFetchDbDiagnostics() {
      if (this.retryAttempts >= this.$options.maxRetryAttempts) {
        this.clearFetchRetries();
        this.error = s__(
          'DatabaseDiagnostics|The database diagnostic job is taking longer than expected. You can check back later or try running it again.',
        );
      } else {
        this.retryAttempts += 1;
        this.fetchRetryIds.push(
          setTimeout(() => this.fetchDbDiagnostics({ retry: true }), this.$options.retryIntervalMs),
        );
      }
    },
    async runDatabaseDiagnostics() {
      this.isLoading = true;
      this.error = null;

      try {
        await axios.post(this.runCollationCheckUrl);
        await this.fetchDbDiagnostics({ retry: true });
      } catch (error) {
        this.clearFetchRetries();
        this.error =
          error.message ?? s__('DatabaseDiagnostics|An error occurred while starting diagnostics');
      }
    },
    clearFetchRetries() {
      this.fetchRetryIds.forEach(clearTimeout);

      this.fetchRetryIds = [];
      this.isLoading = false;
      this.retryAttempts = 0;
    },
  },
};
</script>

<template>
  <main>
    <section class="gl-mb-5">
      <h2 data-testid="title">
        {{ s__('DatabaseDiagnostics|Collation health check') }}
      </h2>
      <p class="gl-text-gray-500">
        {{
          s__(
            'DatabaseDiagnostics|Detect collation-related index corruption issues that might occur after OS upgrade',
          )
        }}
      </p>
      <p v-if="formattedLastRunAt" class="gl-text-sm gl-text-gray-500" data-testid="last-run">
        {{ formattedLastRunAt }}
      </p>

      <gl-button
        variant="confirm"
        :disabled="isLoading"
        data-testid="run-diagnostics-button"
        @click="runDatabaseDiagnostics"
      >
        {{ s__('DatabaseDiagnostics|Run collation check') }}
      </gl-button>
    </section>

    <p v-if="isLoading">
      <gl-skeleton-loader>
        <rect style="width: 100%" height="20" y="0" />
        <rect style="width: 100%" height="15" y="25" />
        <rect style="width: 100%" height="5" y="50" />
        <rect style="width: 100%" height="5" y="60" />
        <rect style="width: 100%" height="5" y="70" />
        <rect style="width: 100%" height="5" y="80" />
        <rect style="width: 100%" height="5" y="90" />
        <rect style="width: 100%" height="5" y="100" />
      </gl-skeleton-loader>
    </p>

    <gl-alert v-else-if="error" variant="danger" data-testid="error-alert" @dismiss="error = null">
      {{ error }}
    </gl-alert>

    <template v-else-if="hasDbDiagnostics">
      <db-diagnostic-results
        v-for="(dbDiagnosticResult, dbName) in dbDiagnostics.databases"
        :key="dbName"
        :db-name="dbName"
        :db-diagnostic-result="dbDiagnosticResult"
      />

      <db-issues-cta v-if="hasIssues" />
    </template>

    <gl-alert v-else variant="info" data-testid="no-results-message" :dismissible="false">
      {{
        s__(
          'DatabaseDiagnostics|No diagnostics have been run yet. Click "Run Collation Check" to analyze your database for potential collation issues.',
        )
      }}
    </gl-alert>
  </main>
</template>
