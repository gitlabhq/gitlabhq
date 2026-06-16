<script>
import { isString, merge } from 'lodash-es';
import { GlButton, GlLink, GlSegmentedControl, GlSprintf } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import glLicensedFeaturesMixin from '~/vue_shared/mixins/gl_licensed_features_mixin';
import { VARIANT_DANGER, VARIANT_INFO, VARIANT_WARNING } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';
import ExtendedDashboardPanel from '~/vue_shared/components/customizable_dashboard/extended_dashboard_panel.vue';
import dataSources from 'ee_else_ce/analytics/analytics_dashboards/data_sources';
import visualizations from 'ee_else_ce/analytics/analytics_dashboards/components/visualizations';
import {
  PANEL_TROUBLESHOOTING_URL,
  VISUALIZATION_DOCUMENTATION_LINKS,
  VISUALIZATION_SLUG_DORA_PERFORMERS_SCORE,
  VISUALIZATION_SLUG_DORA_PROJECTS_COMPARISON,
  VISUALIZATION_SLUG_VSD_DORA_METRICS_TABLE,
  VISUALIZATION_SLUG_VSD_SECURITY_METRICS_TABLE,
} from '../constants';
import { isEmptyPanelData } from '../utils';

export default {
  name: 'AnalyticsDashboardPanel',
  components: {
    ExtendedDashboardPanel,
    GlLink,
    GlSegmentedControl,
    GlSprintf,
    GlButton,
    ...visualizations,
  },
  mixins: [glAbilitiesMixin(), glLicensedFeaturesMixin()],
  inject: [
    'namespaceFullPath',
    'namespaceName',
    'dataSourceClickhouse',
    'overviewCountsAggregationEnabled',
  ],
  props: {
    visualization: {
      type: Object,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    queryOverrides: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    filters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    tooltip: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    views: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      errors: [],
      warnings: [],
      alerts: [],
      alertTitle: '',
      alertDescription: '',
      alertDescriptionLink: '',
      canRetryError: false,
      data: null,
      loading: false,
      loadingDelayed: false,
      currentRequestNumber: 0,
      visualizationOptionOverrides: {},
      visualizationQueryOverrides: {},
      selectedViewIndex: 0,
    };
  },
  computed: {
    currentVisualization() {
      return this.views[this.selectedViewIndex]?.visualization ?? this.visualization;
    },
    segmentOptions() {
      return this.views.map((view, index) => ({ value: index, text: view.text }));
    },
    validationErrors() {
      return this.currentVisualization?.errors;
    },
    hasValidationErrors() {
      return Boolean(this.validationErrors);
    },
    showEmptyState() {
      return !this.showAlertState && isEmptyPanelData(this.currentVisualization.type, this.data);
    },
    alertVariant() {
      if (this.hasAccessError || this.errors.length > 0) return VARIANT_DANGER;
      if (this.warnings.length > 0) return VARIANT_WARNING;
      if (this.alerts.length > 0 || this.alertDescription.length) return VARIANT_INFO;
      return null;
    },
    isErrorAlert() {
      return this.alertVariant === VARIANT_DANGER;
    },
    showAlertState() {
      return (
        this.hasAccessError ||
        Boolean(this.alertMessages.length > 0 || this.alertDescription.length)
      );
    },
    alertMessages() {
      return [...this.errors, ...this.warnings, ...this.alerts].filter(this.isValidAlertMessage);
    },
    namespace() {
      return this.namespaceFullPath;
    },
    subtitle() {
      return this.visualizationOptionOverrides?.subtitle;
    },
    panelTitle() {
      return this.visualizationOptions?.title ?? this.title;
    },
    visualizationOptions() {
      return merge({}, this.currentVisualization.options, this.visualizationOptionOverrides);
    },
    aggregatedQuery() {
      return {
        ...this.currentVisualization.data.query,
        ...this.queryOverrides,
        ...this.visualizationQueryOverrides,
      };
    },
    isPermitted() {
      switch (this.currentVisualization.slug) {
        case VISUALIZATION_SLUG_VSD_SECURITY_METRICS_TABLE:
          return this.glAbilities?.readSecurityResource;
        case VISUALIZATION_SLUG_VSD_DORA_METRICS_TABLE:
        case VISUALIZATION_SLUG_DORA_PROJECTS_COMPARISON:
        case VISUALIZATION_SLUG_DORA_PERFORMERS_SCORE:
          return this.glAbilities?.readDora4Analytics;
        default:
          return true;
      }
    },
    isLicensed() {
      switch (this.currentVisualization.slug) {
        case VISUALIZATION_SLUG_VSD_SECURITY_METRICS_TABLE:
          return this.glLicensedFeatures?.securityDashboard;
        case VISUALIZATION_SLUG_VSD_DORA_METRICS_TABLE:
        case VISUALIZATION_SLUG_DORA_PROJECTS_COMPARISON:
        case VISUALIZATION_SLUG_DORA_PERFORMERS_SCORE:
          return this.glLicensedFeatures?.dora4Analytics;
        default:
          return true;
      }
    },
    hasAccessError() {
      return !this.isLicensed || !this.isPermitted;
    },
    accessErrorMessage() {
      if (!this.isLicensed) {
        return __('This feature requires an Ultimate plan %{linkStart}Learn more%{linkEnd}.');
      }
      if (!this.isPermitted) {
        return s__(
          'Analytics|You have insufficient %{linkStart}permissions%{linkEnd} to view this panel.',
        );
      }

      return null;
    },
    visualizationDocsLink() {
      return VISUALIZATION_DOCUMENTATION_LINKS[this.currentVisualization.slug] || '';
    },
    bodyContentClasses() {
      return this.hasAccessError ? 'gl-content-center' : '';
    },
    panelTooltip() {
      if (this.tooltip?.description) return this.tooltip;

      if (this.visualizationOptions?.tooltip?.description) return this.visualizationOptions.tooltip;

      return undefined;
    },
  },
  watch: {
    currentVisualization: {
      handler: 'fetchData',
      immediate: true,
    },
    queryOverrides: 'fetchData',
    visualizationQueryOverrides: 'fetchData',
    filters: 'fetchData',
  },
  methods: {
    async importDataSourceModule(dataType) {
      const module = await dataSources[dataType]();
      return module.default;
    },
    isValidAlertMessage(message) {
      return isString(message) || (isString(message.link) && isString(message.description));
    },
    onUpdateQuery(queryOverrides) {
      this.visualizationQueryOverrides = {
        ...this.visualizationQueryOverrides,
        ...queryOverrides,
      };
    },
    async fetchData() {
      if (this.hasValidationErrors) {
        this.setAlerts({
          errors: this.validationErrors,
          canRetry: false,
          title: s__('Analytics|Invalid visualization configuration'),
          description: s__(
            'Analytics|Something is wrong with your panel visualization configuration. See %{linkStart}troubleshooting documentation%{linkEnd}.',
          ),
        });
        return;
      }

      const { aggregatedQuery, filters } = this;
      const { type: dataType } = this.currentVisualization.data;
      this.loading = true;
      this.clearAlerts();
      const requestNumber = this.currentRequestNumber + 1;
      this.currentRequestNumber = requestNumber;

      try {
        const fetch = await this.importDataSourceModule(dataType);

        const data = await fetch({
          title: this.title,
          namespace: this.namespace,
          query: aggregatedQuery,
          visualizationType: this.currentVisualization.type,
          visualizationOptions: this.currentVisualization.options,
          setAlerts: this.setAlerts,
          filters,
          onRequestDelayed: () => {
            this.loadingDelayed = true;
          },
          // NOTE: the `setVisualizationOverrides` callback allows us to update visualization options before render but after
          //       the data fetch, allowing us to include fetched data in the visualization options
          setVisualizationOverrides: ({ visualizationOptionOverrides = {} }) => {
            this.visualizationOptionOverrides = visualizationOptionOverrides;
          },
          dataSourceClickhouse: this.dataSourceClickhouse,
          overviewCountsAggregationEnabled: this.overviewCountsAggregationEnabled,
        });

        if (this.currentRequestNumber === requestNumber) {
          this.data = data;
        }
      } catch (error) {
        const isCubeJsBadRequest = this.isCubeJsBadRequest(error);
        const additionalErrorDetails = isCubeJsBadRequest ? error.response?.message : null;

        this.setAlerts({
          errors: [error, additionalErrorDetails].filter(Boolean),
          title: s__('Analytics|Failed to fetch data'),
          description: s__(
            'Analytics|Something went wrong while connecting to your data source. See %{linkStart}troubleshooting documentation%{linkEnd}.',
          ),

          // bad or malformed CubeJS query, retry won't fix
          canRetry: !isCubeJsBadRequest,
        });
      } finally {
        this.loading = false;
        this.loadingDelayed = false;
      }
    },
    clearAlerts() {
      this.errors = [];
      this.warnings = [];
      this.alerts = [];
      this.alertDescription = '';
      this.descriptionLink = '';
      this.alertTitle = '';
    },
    setAlerts({
      errors = [],
      warnings = [],
      alerts = [],
      title = '',
      description = '',
      descriptionLink = '',
      canRetry = true,
    }) {
      this.canRetryError = canRetry;

      this.errors = errors;
      this.warnings = warnings;
      this.alerts = alerts;

      // Only capture in sentry when we are using the error/danger variant
      // Warning / Info variants do no correlate to errors
      errors.forEach((alert) => Sentry.captureException(alert));

      this.alertDescription = description;
      this.alertDescriptionLink = descriptionLink || this.$options.PANEL_TROUBLESHOOTING_URL;
      this.alertTitle = title;
    },
    isCubeJsBadRequest(error) {
      return Boolean(error.status === HTTP_STATUS_BAD_REQUEST && error.response?.message);
    },
  },
  PANEL_TROUBLESHOOTING_URL,
};
</script>

<template>
  <extended-dashboard-panel
    :title="panelTitle"
    :subtitle="subtitle"
    :tooltip="panelTooltip"
    :loading="loading"
    :loading-delayed="loadingDelayed"
    :show-alert-state="showAlertState"
    :alert-variant="alertVariant"
    :alert-popover-title="alertTitle"
    :body-content-classes="bodyContentClasses"
  >
    <template v-if="views.length" #filters>
      <gl-segmented-control v-model="selectedViewIndex" :options="segmentOptions" />
    </template>

    <template #body>
      <div
        v-if="hasAccessError"
        class="gl-flex gl-items-center gl-justify-center"
        data-testid="dashboard-panel-access-warning"
      >
        <span>
          <gl-sprintf :message="accessErrorMessage">
            <template #link="{ content }">
              <gl-link :href="visualizationDocsLink">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
      </div>

      <span v-else-if="isErrorAlert" class="gl-text-subtle" data-testid="alert-body">
        {{ s__('Analytics|Something went wrong.') }}
      </span>

      <span v-else-if="showEmptyState" class="gl-text-subtle">
        {{ s__('Analytics|No results match your query or filter.') }}
      </span>

      <component
        :is="currentVisualization.type"
        v-else
        class="gl-overflow-y-hidden"
        :data="data"
        :options="visualizationOptions"
        :query="aggregatedQuery"
        @set-alerts="setAlerts"
        @update-query="onUpdateQuery"
      />
    </template>

    <template #alert-popover>
      <gl-sprintf :message="alertDescription">
        <template #link="{ content }">
          <gl-link :href="alertDescriptionLink" class="gl-text-sm">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <ul v-if="alertMessages.length" data-testid="alert-messages" class="gl-mb-0">
        <li v-for="(message, i) in alertMessages" :key="`alert-message-${i}`">
          <span v-if="message.link && message.description">
            <gl-sprintf :message="message.description">
              <template #link="{ content }">
                <gl-link :href="message.link" class="gl-text-sm">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
          <span v-else>{{ message }}</span>
        </li>
      </ul>
      <gl-button v-if="canRetryError" class="gl-mt-3 gl-block" @click="fetchData">{{
        __('Retry')
      }}</gl-button>
    </template>
  </extended-dashboard-panel>
</template>
