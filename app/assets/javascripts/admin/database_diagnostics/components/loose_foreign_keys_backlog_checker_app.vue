<script>
import { GlAlert, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { __, s__, sprintf } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import LfkBacklogResults from './lfk_backlog_results.vue';

export default {
  name: 'LooseForeignKeysBacklogCheckerApp',
  components: {
    GlAlert,
    GlButton,
    GlSkeletonLoader,
    LfkBacklogResults,
  },
  retryIntervalMs: 5000, // 5 seconds
  maxRetryAttempts: 60, // 5 minutes total (60 × 5 seconds)
  inject: ['runLfkBacklogCheckUrl', 'lfkBacklogCheckResultsUrl'],
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
      return Boolean(this.dbDiagnostics?.connections);
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
        const { data } = await axios.get(this.lfkBacklogCheckResultsUrl);

        if (data?.error) {
          // The worker caches a { error, message } payload on failure, served with a 200.
          this.dbDiagnostics = null;
          this.error = data.message;
        } else if (data?.connections) {
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
        await axios.post(this.runLfkBacklogCheckUrl);
        await this.fetchDbDiagnostics({ retry: true });
      } catch (error) {
        this.clearFetchRetries();
        this.error =
          error.response?.data?.error ??
          s__('DatabaseDiagnostics|An error occurred while starting diagnostics');
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
        {{ s__('DatabaseDiagnostics|Loose foreign keys cleanup backlog') }}
      </h2>
      <p>
        {{
          s__(
            'DatabaseDiagnostics|Detect loose foreign key deleted records that are not being cleaned up. A growing backlog, especially an old one, can eventually break database migrations.',
          )
        }}
      </p>
      <p v-if="formattedLastRunAt" class="gl-text-sm gl-text-subtle" data-testid="last-run">
        {{ formattedLastRunAt }}
      </p>

      <gl-button
        :disabled="isLoading"
        data-testid="run-diagnostics-button"
        @click="runDatabaseDiagnostics"
      >
        {{ s__('DatabaseDiagnostics|Run backlog check') }}
      </gl-button>
    </section>

    <p v-if="isLoading">
      <gl-skeleton-loader>
        <rect style="width: 100%" height="20" y="0" />
        <rect style="width: 100%" height="15" y="25" />
        <rect style="width: 100%" height="5" y="50" />
        <rect style="width: 100%" height="5" y="60" />
      </gl-skeleton-loader>
    </p>

    <gl-alert v-else-if="error" variant="danger" data-testid="error-alert" @dismiss="error = null">
      {{ error }}
    </gl-alert>

    <template v-else-if="hasDbDiagnostics">
      <lfk-backlog-results
        v-for="(backlog, connectionName) in dbDiagnostics.connections"
        :key="connectionName"
        :connection-name="connectionName"
        :backlog="backlog"
      />
    </template>
  </main>
</template>
