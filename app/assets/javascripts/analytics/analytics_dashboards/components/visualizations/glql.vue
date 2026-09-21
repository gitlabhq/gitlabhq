<script>
import { __, s__ } from '~/locale';
import GlqlResolver from '~/glql/components/common/resolver.vue';
import ViewSourceModal from '~/glql/components/common/view_source_modal.vue';
import { copyQuerySource } from '~/glql/utils/common';
import { copyGLQLContents } from '~/glql/utils/copy_as_gfm';

export default {
  name: 'GlqlVisualization',
  components: {
    GlqlResolver,
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
  emits: ['set-alerts', 'set-actions', 'reload'],
  data() {
    return {
      resolverResult: undefined,
      modalVisible: false,
    };
  },
  computed: {
    showEmptyState() {
      return this.resolverResult?.data?.nodes?.length === 0;
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
    resolverKey() {
      return `${this.isProject}|${this.namespace}|${this.data}`;
    },
    // Null, not an empty object, so the resolver falls back to deriving the namespace from the URL.
    scope() {
      if (!this.namespace) return null;

      return this.isProject ? { project: this.namespace } : { group: this.namespace };
    },
  },
  watch: {
    data() {
      this.resolverResult = undefined;
    },
    // Also clears the empty state, so the resolver remounts under the new key.
    scope() {
      this.resolverResult = undefined;
    },
  },
  methods: {
    handleResolverChange({ data, config, fields, error }) {
      this.resolverResult = { data, config, fields };

      const actions = [];
      if (error) {
        this.$emit('set-alerts', {
          errors: [error],
          title: s__('AnalyticsDashboards|An error occurred when trying to display this panel'),
          description: error.message,
          // With the kebab's Reload gone, the alert popover's Retry is the only way back.
          canRetry: !this.showActions,
        });
      } else {
        actions.push(
          { text: __('View source'), action: () => this.viewSource() },
          { text: __('Copy source'), action: () => this.copySource() },
        );

        // "Copy contents" is only rendered if there are results to copy.
        if (data?.count) {
          actions.push({ text: __('Copy contents'), action: () => this.copyAsGFM() });
        }
      }

      actions.push({ text: __('Reload'), action: () => this.$emit('reload') });
      this.$emit('set-actions', this.showActions ? actions : []);
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
    <span v-if="showEmptyState" class="gl-text-subtle">
      {{ s__('Analytics|No results match your query or filter.') }}
    </span>

    <glql-resolver
      v-else
      ref="resolver"
      :key="resolverKey"
      :glql-query="data"
      :comparison="comparison"
      :scope="scope"
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
