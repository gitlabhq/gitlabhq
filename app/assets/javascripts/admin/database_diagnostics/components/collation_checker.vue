<script>
import { GlAlert, GlButton, GlIcon, GlLoadingIcon, GlTable, GlBadge, GlCard } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, s__, sprintf } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { bytes } from '~/lib/utils/unit_format';
import { SUPPORT_URL } from '~/sessions/new/constants';

export const POLLING_INTERVAL_MS = 5000; // 5 seconds
export const MAX_POLLING_ATTEMPTS = 60; // 5 minutes total (60 × 5 seconds)

export default {
  name: 'CollationChecker',
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlLoadingIcon,
    GlTable,
    GlBadge,
    GlCard,
  },
  supportUrl: SUPPORT_URL,
  collationMismatchFields: [
    { key: 'collation_name', label: __('Collation Name') },
    { key: 'provider', label: __('Provider') },
    { key: 'stored_version', label: __('Stored Version') },
    { key: 'actual_version', label: __('Actual Version') },
  ],
  corruptedIndexesFields: [
    { key: 'index_name', label: __('Index Name') },
    { key: 'table_name', label: __('Table') },
    { key: 'affected_columns', label: __('Affected Columns') },
    { key: 'index_type', label: __('Type') },
    { key: 'is_unique', label: __('Unique') },
    { key: 'size', label: __('Size') },
    { key: 'corruption_types', label: __('Issues') },
  ],
  props: {
    runCollationCheckUrl: {
      type: String,
      required: true,
    },
    collationCheckResultsUrl: {
      type: String,
      required: true,
    },
    pollingIntervalMs: {
      type: Number,
      required: false,
      default: POLLING_INTERVAL_MS,
    },
    maxPollingAttempts: {
      type: Number,
      required: false,
      default: MAX_POLLING_ATTEMPTS,
    },
  },
  data() {
    return {
      isLoading: false,
      isRunning: false,
      isInitialLoad: true,
      results: null,
      error: null,
      pollingId: null,
      pollingAttempts: 0,
    };
  },
  computed: {
    formattedLastRunAt() {
      if (!this.results?.metadata?.last_run_at) {
        return '';
      }
      return formatDate(new Date(this.results.metadata.last_run_at));
    },
    hasResults() {
      return this.results !== null && this.results.databases;
    },
    hasIssues() {
      if (!this.results?.databases) return false;

      return Object.values(this.results.databases).some((db) => db.corrupted_indexes?.length > 0);
    },
    documentationUrl() {
      return helpPagePath('administration/postgresql/upgrading_os');
    },
    shouldShowNoResultsMessage() {
      return !this.hasResults && !this.isLoading && !this.isRunning && !this.isInitialLoad;
    },
  },
  created() {
    this.fetchResults();
  },
  beforeDestroy() {
    this.stopPolling();
  },
  methods: {
    bytes,
    sprintf,

    async fetchResults() {
      this.isInitialLoad = true;
      this.isLoading = true;
      this.error = null;

      try {
        const { data } = await axios.get(this.collationCheckResultsUrl);
        if (data) {
          this.results = data;
        }
      } catch (error) {
        if (error.response?.status === 404) {
          this.error = null;
        } else {
          this.error =
            error.response?.data?.error ?? __('An error occurred while fetching results');
        }
      } finally {
        this.isLoading = false;
        this.isInitialLoad = false;
      }
    },

    async runDatabaseDiagnostics() {
      this.isLoading = true;
      this.isRunning = true;
      this.error = null;

      try {
        await axios.post(this.runCollationCheckUrl);
        this.startPolling();
      } catch (error) {
        this.isLoading = false;
        this.isRunning = false;
        this.error =
          error.response?.data?.error ?? __('An error occurred while starting diagnostics');
      }
    },

    startPolling() {
      this.stopPolling();

      this.pollingId = setInterval(() => {
        this.pollResults();
      }, this.pollingIntervalMs);
    },

    stopPolling() {
      if (this.pollingId) {
        clearInterval(this.pollingId);
        this.pollingId = null;
      }
      this.pollingAttempts = 0;
    },

    async pollResults() {
      try {
        const { data } = await axios.get(this.collationCheckResultsUrl);

        if (data?.databases) {
          this.results = data;
          this.isLoading = false;
          this.isRunning = false;
          this.stopPolling();
        }
      } catch (error) {
        if (error.response?.status === 404) {
          this.pollingAttempts += 1;

          if (this.pollingAttempts >= this.maxPollingAttempts) {
            this.stopPolling();
            this.isLoading = false;
            this.isRunning = false;
            this.error = s__(
              'DatabaseDiagnostics|The database diagnostic job is taking longer than expected. You can check back later or try running it again.',
            );
          }
          return;
        }

        this.isLoading = false;
        this.isRunning = false;
        this.stopPolling();
        this.error = error.response?.data?.error ?? __('An error occurred while fetching results');
      }
    },

    hasMismatches(dbResults) {
      return dbResults.collation_mismatches?.length > 0;
    },

    hasCorruptedIndexes(dbResults) {
      return dbResults.corrupted_indexes?.length > 0;
    },

    formatBytes(byteSize) {
      return this.bytes(byteSize);
    },
  },
};
</script>

<template>
  <div class="gl-mt-3">
    <div class="gl-display-flex gl-justify-content-between gl-mb-5 gl-flex-wrap gl-gap-3">
      <div>
        <h2 class="gl-heading-4" data-testid="title">
          {{ s__('DatabaseDiagnostics|Collation Health Check') }}
        </h2>
        <p class="gl-text-secondary">
          {{
            s__(
              'DatabaseDiagnostics|Detect collation-related index corruption issues that may occur after OS upgrades',
            )
          }}
          <small
            v-if="results && results.metadata && results.metadata.last_run_at"
            class="gl-ml-2"
            data-testid="last-run"
          >
            {{
              sprintf(s__('DatabaseDiagnostics|Last checked: %{timestamp}'), {
                timestamp: formattedLastRunAt,
              })
            }}
          </small>
        </p>
      </div>
      <div>
        <gl-button
          variant="confirm"
          :disabled="isLoading || isRunning"
          data-testid="run-diagnostics-button"
          @click="runDatabaseDiagnostics"
        >
          {{ s__('DatabaseDiagnostics|Run Collation Check') }}
        </gl-button>
      </div>
    </div>

    <gl-alert v-if="isInitialLoad" variant="info" data-testid="loading-alert" :dismissible="false">
      <gl-loading-icon size="sm" inline class="gl-mr-2" />
      {{ s__('DatabaseDiagnostics|Checking for recent diagnostic results...') }}
    </gl-alert>

    <gl-alert v-if="isRunning" variant="info" data-testid="running-alert" :dismissible="false">
      <gl-loading-icon size="sm" inline class="gl-mr-2" />
      {{ s__('DatabaseDiagnostics|Running diagnostics...') }}
    </gl-alert>

    <gl-alert v-if="error" variant="danger" data-testid="error-alert" @dismiss="error = null">
      {{ error }}
    </gl-alert>

    <!-- Results Section -->
    <template v-if="hasResults && !isRunning">
      <div
        v-for="(dbResults, dbName) in results.databases"
        :key="dbName"
        class="gl-mt-4"
        :data-testid="`database-${dbName}`"
      >
        <h3 class="gl-heading-5">
          {{ sprintf(s__('DatabaseDiagnostics|Database: %{name}'), { name: dbName }) }}
        </h3>

        <!-- Collation Mismatches Section -->
        <gl-card class="gl-mt-3" data-testid="collation-mismatches-section">
          <template #header>
            <div class="gl-display-flex gl-align-items-center">
              <gl-icon
                :name="hasMismatches(dbResults) ? 'information-o' : 'check-circle-filled'"
                :variant="hasMismatches(dbResults) ? 'info' : 'success'"
                class="gl-mr-2"
                data-testid="collation-mismatches-icon"
              />
              <strong>{{ __('Collation Mismatches') }}</strong>
            </div>
          </template>

          <template v-if="hasMismatches(dbResults)">
            <gl-alert
              variant="info"
              data-testid="collation-info-alert"
              :dismissible="false"
              class="gl-mb-3"
            >
              {{
                s__(
                  'DatabaseDiagnostics|Collation mismatches are shown for informational purposes and may not indicate a problem.',
                )
              }}
            </gl-alert>
            <gl-table
              :items="dbResults.collation_mismatches"
              :fields="$options.collationMismatchFields"
              bordered
              striped
              stacked="sm"
              data-testid="collation-mismatches-table"
            />
          </template>
          <template v-else>
            <gl-alert
              variant="success"
              data-testid="no-collation-mismatches-alert"
              :dismissible="false"
            >
              {{ __('No collation mismatches detected.') }}
            </gl-alert>
          </template>
        </gl-card>

        <!-- Corrupted Indexes Section -->
        <gl-card class="gl-mt-3" data-testid="corrupted-indexes-section">
          <template #header>
            <div class="gl-display-flex gl-align-items-center">
              <gl-icon
                :name="hasCorruptedIndexes(dbResults) ? 'error' : 'check-circle-filled'"
                :variant="hasCorruptedIndexes(dbResults) ? 'danger' : 'success'"
                class="gl-mr-2"
                data-testid="corrupted-indexes-icon"
              />
              <strong>{{ __('Corrupted Indexes') }}</strong>
              <gl-badge
                v-if="hasCorruptedIndexes(dbResults)"
                variant="danger"
                class="gl-ml-2"
                data-testid="corrupted-indexes-count"
              >
                {{ dbResults.corrupted_indexes.length }}
              </gl-badge>
            </div>
          </template>

          <template v-if="hasCorruptedIndexes(dbResults)">
            <gl-table
              :items="dbResults.corrupted_indexes"
              :fields="$options.corruptedIndexesFields"
              bordered
              striped
              stacked="sm"
              data-testid="corrupted-indexes-table"
            >
              <template #cell(index_type)="{ value }">
                {{ value }}
              </template>

              <template #cell(is_unique)="{ value }">
                {{ value ? __('Yes') : __('No') }}
              </template>

              <template #cell(size)="{ item }">
                {{ formatBytes(item.size_bytes) }}
              </template>

              <template #cell(corruption_types)="{ value }">
                <gl-badge
                  v-for="type in value"
                  :key="type"
                  :variant="type === 'structural' ? 'danger' : 'warning'"
                  class="gl-mr-2"
                  :data-testid="`corruption-type-${type}`"
                >
                  {{ type === 'structural' ? __('Structural') : __('Duplicates') }}
                </gl-badge>
              </template>
            </gl-table>
          </template>
          <template v-else>
            <gl-alert
              variant="success"
              data-testid="no-corrupted-indexes-alert"
              :dismissible="false"
            >
              {{ __('No corrupted indexes detected.') }}
            </gl-alert>
          </template>
        </gl-card>
      </div>

      <!-- Action Card -->
      <gl-card v-if="hasIssues" class="gl-mt-5" data-testid="action-card">
        <template #header>
          <div class="gl-display-flex gl-align-items-center">
            <gl-icon name="information-o" class="gl-mr-2" />
            <strong>{{ s__('DatabaseDiagnostics|Issues detected') }}</strong>
          </div>
        </template>

        <p>
          {{
            s__(
              'DatabaseDiagnostics|These issues require manual remediation. Read our documentation on PostgreSQL OS upgrades for step-by-step instructions.',
            )
          }}
        </p>

        <div class="gl-display-flex gl-flex-wrap gl-gap-3">
          <gl-button
            :href="documentationUrl"
            target="_blank"
            icon="document"
            category="primary"
            variant="confirm"
            data-testid="learn-more-button"
          >
            {{ s__('DatabaseDiagnostics|Learn more') }}
          </gl-button>

          <gl-button
            :href="$options.supportUrl"
            target="_blank"
            icon="support"
            category="secondary"
            data-testid="contact-support-button"
          >
            {{ s__('DatabaseDiagnostics|Contact Support') }}
          </gl-button>
        </div>
      </gl-card>
    </template>

    <!-- No Results Yet Message -->
    <gl-alert
      v-if="shouldShowNoResultsMessage"
      variant="info"
      data-testid="no-results-message"
      :dismissible="false"
    >
      {{
        s__(
          'DatabaseDiagnostics|No diagnostics have been run yet. Click "Run Collation Check" to analyze your database for potential collation issues.',
        )
      }}
    </gl-alert>
  </div>
</template>
