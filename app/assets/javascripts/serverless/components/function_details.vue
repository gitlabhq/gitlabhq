<script>
import _ from 'underscore';
import { mapState, mapActions, mapGetters } from 'vuex';
import PodBox from './pod_box.vue';
import Url from './url.vue';
import AreaChart from './area.vue';
import MissingPrometheus from './missing_prometheus.vue';

export default {
  components: {
    PodBox,
    Url,
    AreaChart,
    MissingPrometheus,
  },
  props: {
    func: {
      type: Object,
      required: true,
    },
    hasPrometheus: {
      type: Boolean,
      required: false,
      default: false,
    },
    clustersPath: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      elWidth: 0,
    };
  },
  computed: {
    name() {
      return this.func.name;
    },
    description() {
      return _.isString(this.func.description) ? this.func.description : '';
    },
    funcUrl() {
      return this.func.url;
    },
    podCount() {
      return Number(this.func.podcount) || 0;
    },
    ...mapState(['graphData', 'hasPrometheusData']),
    ...mapGetters(['hasPrometheusMissingData']),
  },
  created() {
    this.fetchMetrics({
      metricsPath: this.func.metricsUrl,
      hasPrometheus: this.hasPrometheus,
    });
  },
  mounted() {
    this.elWidth = this.$el.clientWidth;
  },
  methods: {
    ...mapActions(['fetchMetrics']),
  },
};
</script>

<template>
  <section id="serverless-function-details">
    <h3 class="serverless-function-name">{{ name }}</h3>
    <div class="append-bottom-default serverless-function-description">
      <div v-for="(line, index) in description.split('\n')" :key="index">{{ line }}</div>
    </div>
    <url :uri="funcUrl" />

    <h4>{{ s__('ServerlessDetails|Kubernetes Pods') }}</h4>
    <div v-if="podCount > 0">
      <p>
        <b v-if="podCount == 1">{{ podCount }} {{ s__('ServerlessDetails|pod in use') }}</b>
        <b v-else>{{ podCount }} {{ s__('ServerlessDetails|pods in use') }}</b>
      </p>
      <pod-box :count="podCount" />
      <p>
        {{
          s__('ServerlessDetails|Number of Kubernetes pods in use over time based on necessity.')
        }}
      </p>
    </div>
    <div v-else>
      <p>{{ s__('ServerlessDetails|No pods loaded at this time.') }}</p>
    </div>

    <area-chart v-if="hasPrometheusData" :graph-data="graphData" :container-width="elWidth" />
    <missing-prometheus
      v-if="!hasPrometheus || hasPrometheusMissingData"
      :help-path="helpPath"
      :clusters-path="clustersPath"
      :missing-data="hasPrometheusMissingData"
    />
  </section>
</template>
