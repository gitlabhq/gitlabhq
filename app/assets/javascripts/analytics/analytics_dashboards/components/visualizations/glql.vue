<script>
import { __, s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { EXECUTION_QUEUE_DASHBOARD } from '~/glql/constants';
import GlqlResolver from '~/glql/components/common/resolver.vue';
import ViewSourceModal from '~/glql/components/common/view_source_modal.vue';
import { copyQuerySource } from '~/glql/utils/common';
import { copyGLQLContents } from '~/glql/utils/copy_as_gfm';
import {
  classifyGlqlError,
  GLQL_ERROR_GENERIC,
  GLQL_ERROR_INVALID_QUERY,
  GLQL_ERROR_NO_ACCESS,
  GLQL_ERROR_NOT_CONFIGURED,
  GLQL_ERROR_RATE_LIMITED,
  GLQL_ERROR_TIMEOUT,
  GLQL_ERROR_UNAVAILABLE,
} from '~/glql/utils/error_classifier';
import PanelState from '~/analytics/shared/components/panel_state.vue';
import {
  PANEL_STATE_ERROR,
  PANEL_STATE_ERROR_NO_RETRY,
  PANEL_STATE_NO_ACCESS,
  PANEL_STATE_NO_DATA,
  PANEL_STATE_NOT_CONFIGURED,
  PANEL_STATE_UNAVAILABLE,
} from '~/analytics/shared/constants';

const STATE_VARIANT_BY_ERROR_CATEGORY = {
  [GLQL_ERROR_NO_ACCESS]: PANEL_STATE_NO_ACCESS,
  [GLQL_ERROR_NOT_CONFIGURED]: PANEL_STATE_NOT_CONFIGURED,
  [GLQL_ERROR_UNAVAILABLE]: PANEL_STATE_UNAVAILABLE,
  [GLQL_ERROR_TIMEOUT]: PANEL_STATE_ERROR,
  [GLQL_ERROR_RATE_LIMITED]: PANEL_STATE_ERROR_NO_RETRY,
  // Deterministic query errors: a retry re-runs the same query and fails the same way.
  [GLQL_ERROR_INVALID_QUERY]: PANEL_STATE_ERROR_NO_RETRY,
  [GLQL_ERROR_GENERIC]: PANEL_STATE_ERROR,
};

export default {
  name: 'GlqlVisualization',
  EXECUTION_QUEUE_DASHBOARD,
  PANEL_STATE_NO_DATA,
  components: {
    GlqlResolver,
    PanelState,
    ViewSourceModal,
  },
  props: {
    data: {
      type: String,
      required: false,
      default: '',
    },
    namespace: {
      type: String,
      required: false,
      default: '',
    },
    isProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['set-actions', 'reload'],
  data() {
    return {
      resolverResult: undefined,
      stateVariant: null,
      stateDescription: '',
      retryCount: 0,
      modalVisible: false,
    };
  },
  computed: {
    showEmptyState() {
      return this.resolverResult?.data?.nodes?.length === 0;
    },
    // Stat tiles are too small for the centered state block. A parse failure produces
    // no config and falls back to the full-size state; only the compiler may read the
    // query text, so the display type is not recovered from it here.
    compactState() {
      return this.resolverResult?.config?.display === 'stat';
    },
    emptyStateTitle() {
      return this.options.emptyState?.title ?? '';
    },
    emptyStateDescription() {
      return this.options.emptyState?.description ?? '';
    },
    // GlDashboardPanel hides its actions dropdown when a panel has no actions, so opting out
    // means emitting an empty list. Panels opt out entirely, error state included.
    showActions() {
      return this.options.showActions ?? true;
    },
    // Bundled here rather than passed down as separate options: the resolver is shared with
    // GLQL blocks in comments and descriptions, which have no dashboard to configure a trend.
    comparison() {
      if (!this.options.comparisonQuery) return null;

      return { query: this.options.comparisonQuery, metric: this.options.trendMetric };
    },
    // The resolver does not re-query on prop changes. Remounting it discards the old instance
    // along with its in-flight requests, so a superseded result can never arrive here.
    // `retryCount` is part of the key because a retry re-runs the same query: nothing else
    // in the key changes, so only a remount forces re-execution.
    resolverKey() {
      return `${this.retryCount}|${this.isProject}|${this.namespace}|${this.data}`;
    },
    // Null, not an empty object, so the resolver falls back to deriving the namespace from the URL.
    scope() {
      if (!this.namespace) return null;

      return this.isProject ? { project: this.namespace } : { group: this.namespace };
    },
  },
  watch: {
    data() {
      this.resetState();
    },
    // Also clears the empty and error states, so the resolver remounts under the new key.
    scope() {
      this.resetState();
    },
  },
  methods: {
    resetState() {
      this.resolverResult = undefined;
      this.stateVariant = null;
      this.stateDescription = '';
    },
    handleResolverChange({ data, config, fields, error }) {
      this.resolverResult = { data, config, fields };

      const actions = [];
      if (error) {
        const category = classifyGlqlError(error);
        // Access, availability and query mistakes are expected states; only
        // unexpected failures are errors worth reporting.
        if (category === GLQL_ERROR_GENERIC) Sentry.captureException(error);

        // Rows already on screen (a failed continuation page) stay visible;
        // replacing them with an error state would destroy loaded data.
        this.stateVariant = data?.nodes?.length ? null : STATE_VARIANT_BY_ERROR_CATEGORY[category];

        if (category === GLQL_ERROR_TIMEOUT) {
          this.stateDescription = s__(
            'Analytics|The query timed out. Select a shorter date range and try again.',
          );
        } else if (category === GLQL_ERROR_INVALID_QUERY) {
          // The message is the only way a dashboard author can fix their query.
          this.stateDescription = error.message || '';
        } else {
          this.stateDescription = '';
        }
      } else {
        this.stateVariant = null;
        this.stateDescription = '';

        actions.push(
          { text: __('View source'), action: () => this.viewSource() },
          { text: __('Copy source'), action: () => this.copySource() },
        );

        // "Copy contents" is only rendered if there are results to copy.
        if (data?.count) {
          actions.push({ text: __('Copy contents'), action: () => this.copyAsGFM() });
        }
      }

      actions.push({ text: __('Reload'), action: () => this.reload() });
      this.$emit('set-actions', this.showActions ? actions : []);
    },
    retry() {
      this.resetState();
      this.retryCount += 1;
    },
    // The panel re-fetches its data source, but that yields the same query string, which
    // alone would never remount the resolver: bump the key too so the query actually re-runs.
    reload() {
      this.retry();
      this.$emit('reload');
    },
    viewSource() {
      this.modalVisible = true;
    },
    copySource() {
      copyQuerySource(this.data);
    },
    async copyAsGFM() {
      await copyGLQLContents({ ...this.resolverResult, el: this.$refs.resolver.$el });
    },
  },
};
</script>

<template>
  <div>
    <panel-state
      v-if="stateVariant"
      :variant="stateVariant"
      :compact="compactState"
      :description="stateDescription"
      @retry="retry"
    />

    <panel-state
      v-else-if="showEmptyState"
      :variant="$options.PANEL_STATE_NO_DATA"
      :compact="compactState"
      :title="emptyStateTitle"
      :description="emptyStateDescription"
    />

    <glql-resolver
      v-else
      ref="resolver"
      :key="resolverKey"
      :glql-query="data"
      :comparison="comparison"
      :scope="scope"
      :queue="$options.EXECUTION_QUEUE_DASHBOARD"
      tracking-event-name="render_analytics_dashboard_glql_panel"
      @change="handleResolverChange"
    />

    <view-source-modal
      v-model="modalVisible"
      :query="data"
      :title="s__('AnalyticsDashboards|Panel query')"
    />
  </div>
</template>
