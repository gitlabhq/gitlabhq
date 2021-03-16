<script>
import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);

export default {
  props: {
    dashboardUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      metricEmbedComponent: null,
      namespace: 'alertMetrics',
    };
  },
  mounted() {
    if (this.dashboardUrl) {
      Promise.all([
        import('~/monitoring/components/embeds/metric_embed.vue'),
        import('~/monitoring/stores'),
      ])
        .then(([{ default: MetricEmbed }, { monitoringDashboard }]) => {
          this.$store = new Vuex.Store({
            modules: {
              [this.namespace]: monitoringDashboard,
            },
          });
          this.metricEmbedComponent = MetricEmbed;
        })
        .catch((e) => Sentry.captureException(e));
    }
  },
};
</script>

<template>
  <div class="gl-py-3">
    <div v-if="dashboardUrl" ref="metricsChart">
      <component
        :is="metricEmbedComponent"
        v-if="metricEmbedComponent"
        :dashboard-url="dashboardUrl"
        :namespace="namespace"
      />
    </div>
    <div v-else ref="emptyState">
      {{ s__("AlertManagement|Metrics weren't available in the alerts payload.") }}
    </div>
  </div>
</template>
