<script>
import { GlAlert, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { __, s__, sprintf } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import SchemaResultsContainer from './schema_results_container.vue';

export default {
  name: 'SchemaCheckerApp',
  components: {
    GlAlert,
    GlButton,
    GlSkeletonLoader,
    SchemaResultsContainer,
  },
  retryIntervalMs: 5000, // 5 seconds
  maxRetryAttempts: 60, // 5 minutes total (60 × 5 seconds)
  inject: ['runSchemaCheckUrl', 'schemaCheckResultsUrl'],
  data() {
    return {
      isLoading: false,
      schemaDiagnostics: null,
      error: null,
      fetchRetryIds: [],
      retryAttempts: 0,
    };
  },
  computed: {
    formattedLastRunAt() {
      if (!this.schemaDiagnostics?.metadata?.last_run_at) return '';

      const timestamp = localeDateFormat.asDateTime.format(
        new Date(this.schemaDiagnostics.metadata.last_run_at),
      );

      return sprintf(s__('DatabaseDiagnostics|Last checked: %{timestamp}'), { timestamp });
    },
    hasSchemaDiagnostics() {
      return Boolean(
        this.schemaDiagnostics?.schema_check_results &&
          Object.keys(this.schemaDiagnostics.schema_check_results).length > 0,
      );
    },
  },
  created() {
    this.fetchSchemaDiagnostics();
  },
  beforeDestroy() {
    this.clearFetchRetries();
  },
  methods: {
    async fetchSchemaDiagnostics({ retry = false } = {}) {
      this.isLoading = true;
      this.error = null;

      try {
        const { data } = await axios.get(this.schemaCheckResultsUrl);

        if (data?.schema_check_results) {
          this.schemaDiagnostics = data;
        }
        this.isLoading = false;
      } catch (error) {
        if (error.response?.status === HTTP_STATUS_NOT_FOUND) {
          if (retry) {
            this.retryFetchSchemaDiagnostics();
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
    retryFetchSchemaDiagnostics() {
      if (this.retryAttempts >= this.$options.maxRetryAttempts) {
        this.clearFetchRetries();
        this.error = s__(
          'DatabaseDiagnostics|The database diagnostic job is taking longer than expected. You can check back later or try running it again.',
        );
      } else {
        this.retryAttempts += 1;
        this.fetchRetryIds.push(
          setTimeout(
            () => this.fetchSchemaDiagnostics({ retry: true }),
            this.$options.retryIntervalMs,
          ),
        );
      }
    },
    async runSchemaDiagnostics() {
      this.isLoading = true;
      this.error = null;

      try {
        await axios.post(this.runSchemaCheckUrl);
        await this.fetchSchemaDiagnostics({ retry: true });
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
        {{ s__('DatabaseDiagnostics|Schema health check') }}
      </h2>
      <p class="gl-text-gray-500">
        {{
          s__('DatabaseDiagnostics|Detect database schema inconsistencies and structural issues')
        }}
      </p>
      <p v-if="formattedLastRunAt" class="gl-text-sm gl-text-gray-500" data-testid="last-run">
        {{ formattedLastRunAt }}
      </p>

      <gl-button
        variant="confirm"
        :disabled="isLoading"
        data-testid="run-diagnostics-button"
        @click="runSchemaDiagnostics"
      >
        {{ s__('DatabaseDiagnostics|Run schema check') }}
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

    <template v-else-if="hasSchemaDiagnostics">
      <schema-results-container :schema-diagnostics="schemaDiagnostics" />
    </template>

    <gl-alert v-else variant="info" data-testid="no-results-message" :dismissible="false">
      {{
        s__(
          'DatabaseDiagnostics|Select "Run Schema Check" to analyze your database schema for potential issues.',
        )
      }}
    </gl-alert>
  </main>
</template>
