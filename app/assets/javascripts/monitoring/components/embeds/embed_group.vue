<script>
import { GlButton, GlCard, GlIcon } from '@gitlab/ui';
import sum from 'lodash/sum';
import { mapState, mapActions, mapGetters } from 'vuex';
import { n__ } from '~/locale';
import { monitoringDashboard } from '~/monitoring/stores';
import MetricEmbed from './metric_embed.vue';

export default {
  components: {
    GlButton,
    GlCard,
    GlIcon,
    MetricEmbed,
  },
  props: {
    urls: {
      type: Array,
      required: true,
      validator: (urls) => urls.length > 0,
    },
  },
  data() {
    return {
      isCollapsed: false,
    };
  },
  computed: {
    ...mapState('embedGroup', ['module']),
    ...mapGetters('embedGroup', ['metricsWithData']),
    arrowIconName() {
      return this.isCollapsed ? 'chevron-right' : 'chevron-down';
    },
    bodyClass() {
      return ['border-top', 'pl-3', 'pt-3', { 'd-none': this.isCollapsed }];
    },
    buttonLabel() {
      return this.isCollapsed
        ? n__('View chart', 'View charts', this.numCharts)
        : n__('Hide chart', 'Hide charts', this.numCharts);
    },
    containerClass() {
      return this.isSingleChart ? 'col-lg-12' : 'col-lg-6';
    },
    numCharts() {
      if (this.metricsWithData === null) {
        return 0;
      }
      return sum(this.metricsWithData);
    },
    isSingleChart() {
      return this.numCharts === 1;
    },
  },
  created() {
    this.urls.forEach((url, index) => {
      const name = this.getNamespace(index);
      this.$store.registerModule(name, monitoringDashboard);
      this.addModule(name);
    });
  },
  methods: {
    ...mapActions('embedGroup', ['addModule']),
    getNamespace(id) {
      return `monitoringDashboard/${id}`;
    },
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
  },
};
</script>
<template>
  <gl-card
    v-show="numCharts > 0"
    class="collapsible-card border p-0 gl-mb-5"
    header-class="d-flex align-items-center border-bottom-0 py-2"
    :body-class="bodyClass"
  >
    <template #header>
      <gl-button
        class="collapsible-card-btn gl-display-flex gl-text-decoration-none gl-reset-color! gl-hover-text-blue-800! gl-shadow-none!"
        :aria-label="buttonLabel"
        variant="link"
        category="tertiary"
        @click="toggleCollapsed"
      >
        <gl-icon class="mr-1" :name="arrowIconName" />
        {{ buttonLabel }}
      </gl-button>
    </template>
    <div class="d-flex flex-wrap">
      <metric-embed
        v-for="(url, index) in urls"
        :key="`${index}/${url}`"
        :dashboard-url="url"
        :namespace="getNamespace(index)"
        :container-class="containerClass"
      />
    </div>
  </gl-card>
</template>
