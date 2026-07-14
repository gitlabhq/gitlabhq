<script>
import { s__ } from '~/locale';
import GlqlResolver from '~/glql/components/common/resolver.vue';

export default {
  name: 'GlqlVisualization',
  components: {
    GlqlResolver,
  },
  props: {
    data: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['set-alerts'],
  data() {
    return {
      resolverData: undefined,
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

      if (!error) return;

      this.$emit('set-alerts', {
        errors: [error],
        title: s__('AnalyticsDashboards|An error occurred when trying to display this panel'),
        description: error.message,
        canRetry: false,
      });
    },
  },
};
</script>

<template>
  <span v-if="showEmptyState" class="gl-text-subtle">
    {{ s__('Analytics|No results match your query or filter.') }}
  </span>

  <glql-resolver
    v-else
    :glql-query="data"
    tracking-event-name="render_analytics_dashboard_glql_panel"
    @change="handleResolverChange"
  />
</template>
