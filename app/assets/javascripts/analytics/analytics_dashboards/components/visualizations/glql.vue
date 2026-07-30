<script>
import { __, s__ } from '~/locale';
import GlqlResolver from '~/glql/components/common/resolver.vue';
import ViewSourceModal from '~/glql/components/common/view_source_modal.vue';
import { copyQuerySource } from '~/glql/utils/common';
import { copyGLQLNodeAsGFM } from '~/glql/utils/copy_as_gfm';

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
  },
  emits: ['set-alerts', 'set-actions', 'reload'],
  data() {
    return {
      resolverData: undefined,
      modalVisible: false,
    };
  },
  computed: {
    showEmptyState() {
      return this.resolverData?.nodes?.length === 0;
    },
  },
  watch: {
    data() {
      this.resolverData = undefined;
    },
  },
  methods: {
    handleResolverChange({ data, error }) {
      this.resolverData = data;

      const actions = [];
      if (error) {
        this.$emit('set-alerts', {
          errors: [error],
          title: s__('AnalyticsDashboards|An error occurred when trying to display this panel'),
          description: error.message,
          canRetry: false,
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
      this.$emit('set-actions', actions);
    },
    viewSource() {
      this.modalVisible = true;
    },
    copySource() {
      copyQuerySource(this.data);
    },
    async copyAsGFM() {
      await copyGLQLNodeAsGFM(this.$refs.resolver.$el);
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
      :glql-query="data"
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
