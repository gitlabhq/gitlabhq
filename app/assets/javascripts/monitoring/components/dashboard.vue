<script>
import _ from 'underscore';
import { mapActions, mapState } from 'vuex';
import VueDraggable from 'vuedraggable';
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormGroup,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import PanelType from 'ee_else_ce/monitoring/components/panel_type.vue';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import Icon from '~/vue_shared/components/icon.vue';
import { getParameterValues, mergeUrlParams, redirectTo } from '~/lib/utils/url_utility';
import invalidUrl from '~/lib/utils/invalid_url';
import DateTimePicker from './date_time_picker/date_time_picker.vue';
import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { getTimeDiff, isValidDate, getAddMetricTrackingOptions } from '../utils';

export default {
  components: {
    VueDraggable,
    PanelType,
    GraphGroup,
    EmptyState,
    Icon,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlModal,
    DateTimePicker,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
    TrackEvent: TrackEventDirective,
  },
  props: {
    externalDashboardUrl: {
      type: String,
      required: false,
      default: '',
    },
    hasMetrics: {
      type: Boolean,
      required: false,
      default: true,
    },
    showPanels: {
      type: Boolean,
      required: false,
      default: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
    settingsPath: {
      type: String,
      required: true,
    },
    clustersPath: {
      type: String,
      required: true,
    },
    tagsPath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    metricsEndpoint: {
      type: String,
      required: true,
    },
    deploymentsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    emptyGettingStartedSvgPath: {
      type: String,
      required: true,
    },
    emptyLoadingSvgPath: {
      type: String,
      required: true,
    },
    emptyNoDataSvgPath: {
      type: String,
      required: true,
    },
    emptyUnableToConnectSvgPath: {
      type: String,
      required: true,
    },
    environmentsEndpoint: {
      type: String,
      required: true,
    },
    currentEnvironmentName: {
      type: String,
      required: true,
    },
    customMetricsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    customMetricsPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    validateQueryPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    dashboardEndpoint: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    currentDashboard: {
      type: String,
      required: false,
      default: '',
    },
    smallEmptyState: {
      type: Boolean,
      required: false,
      default: false,
    },
    alertsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    prometheusAlertsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    rearrangePanelsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      state: 'gettingStarted',
      formIsValid: null,
      selectedTimeWindow: {},
      isRearrangingPanels: false,
      hasValidDates: true,
    };
  },
  computed: {
    canAddMetrics() {
      return this.customMetricsAvailable && this.customMetricsPath.length;
    },
    ...mapState('monitoringDashboard', [
      'dashboard',
      'emptyState',
      'showEmptyState',
      'environments',
      'deploymentData',
      'metricsWithData',
      'useDashboardEndpoint',
      'allDashboards',
      'additionalPanelTypesEnabled',
    ]),
    firstDashboard() {
      return this.environmentsEndpoint.length > 0 && this.allDashboards.length > 0
        ? this.allDashboards[0]
        : {};
    },
    selectedDashboard() {
      return this.allDashboards.find(d => d.path === this.currentDashboard) || this.firstDashboard;
    },
    selectedDashboardText() {
      return this.selectedDashboard.display_name;
    },
    showRearrangePanelsBtn() {
      return !this.showEmptyState && this.rearrangePanelsAvailable;
    },
    addingMetricsAvailable() {
      return IS_EE && this.canAddMetrics && !this.showEmptyState;
    },
    hasHeaderButtons() {
      return (
        this.addingMetricsAvailable ||
        this.showRearrangePanelsBtn ||
        this.selectedDashboard.can_edit ||
        this.externalDashboardUrl.length
      );
    },
  },
  created() {
    this.setEndpoints({
      metricsEndpoint: this.metricsEndpoint,
      environmentsEndpoint: this.environmentsEndpoint,
      deploymentsEndpoint: this.deploymentsEndpoint,
      dashboardEndpoint: this.dashboardEndpoint,
      currentDashboard: this.currentDashboard,
      projectPath: this.projectPath,
    });
  },
  mounted() {
    if (!this.hasMetrics) {
      this.setGettingStartedEmptyState();
    } else {
      const defaultRange = getTimeDiff();
      const start = getParameterValues('start')[0] || defaultRange.start;
      const end = getParameterValues('end')[0] || defaultRange.end;

      const range = {
        start,
        end,
      };

      this.selectedTimeWindow = range;

      if (!isValidDate(start) || !isValidDate(end)) {
        this.hasValidDates = false;
        this.showInvalidDateError();
      } else {
        this.hasValidDates = true;
        this.fetchData(range);
      }
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', [
      'fetchData',
      'setGettingStartedEmptyState',
      'setEndpoints',
      'setPanelGroupMetrics',
    ]),
    updatePanels(key, panels) {
      this.setPanelGroupMetrics({
        panels,
        key,
      });
    },
    removePanel(key, panels, graphIndex) {
      this.setPanelGroupMetrics({
        panels: panels.filter((v, i) => i !== graphIndex),
        key,
      });
    },
    showInvalidDateError() {
      createFlash(s__('Metrics|Link contains an invalid time window.'));
    },
    generateLink(group, title, yLabel) {
      const dashboard = this.currentDashboard || this.firstDashboard.path;
      const params = _.pick({ dashboard, group, title, y_label: yLabel }, value => value != null);
      return mergeUrlParams(params, window.location.href);
    },
    hideAddMetricModal() {
      this.$refs.addMetricModal.hide();
    },
    toggleRearrangingPanels() {
      this.isRearrangingPanels = !this.isRearrangingPanels;
    },
    setFormValidity(isValid) {
      this.formIsValid = isValid;
    },
    submitCustomMetricsForm() {
      this.$refs.customMetricsForm.submit();
    },
    chartsWithData(panels) {
      return panels.filter(panel =>
        panel.metrics.some(metric => this.metricsWithData.includes(metric.metric_id)),
      );
    },
    groupHasData(group) {
      return this.chartsWithData(group.panels).length > 0;
    },
    onDateTimePickerApply(timeWindowUrlParams) {
      return redirectTo(mergeUrlParams(timeWindowUrlParams, window.location.href));
    },
    getAddMetricTrackingOptions,
  },
  addMetric: {
    title: s__('Metrics|Add metric'),
    modalId: 'add-metric',
  },
};
</script>

<template>
  <div class="prometheus-graphs">
    <div class="prometheus-graphs-header gl-p-3 pb-0 border-bottom bg-gray-light">
      <div class="row">
        <template v-if="environmentsEndpoint">
          <gl-form-group
            :label="__('Dashboard')"
            label-size="sm"
            label-for="monitor-dashboards-dropdown"
            class="col-sm-12 col-md-6 col-lg-2"
          >
            <gl-dropdown
              id="monitor-dashboards-dropdown"
              class="mb-0 d-flex js-dashboards-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="selectedDashboardText"
            >
              <gl-dropdown-item
                v-for="dashboard in allDashboards"
                :key="dashboard.path"
                :active="dashboard.path === currentDashboard"
                active-class="is-active"
                :href="`?dashboard=${dashboard.path}`"
                >{{ dashboard.display_name || dashboard.path }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>

          <gl-form-group
            :label="s__('Metrics|Environment')"
            label-size="sm"
            label-for="monitor-environments-dropdown"
            class="col-sm-6 col-md-6 col-lg-2"
          >
            <gl-dropdown
              id="monitor-environments-dropdown"
              class="mb-0 d-flex js-environments-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="currentEnvironmentName"
              :disabled="environments.length === 0"
            >
              <gl-dropdown-item
                v-for="environment in environments"
                :key="environment.id"
                :active="environment.name === currentEnvironmentName"
                active-class="is-active"
                :href="environment.metrics_path"
                >{{ environment.name }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>

          <gl-form-group
            v-if="hasValidDates"
            :label="s__('Metrics|Show last')"
            label-size="sm"
            label-for="monitor-time-window-dropdown"
            class="col-sm-6 col-md-6 col-lg-4"
          >
            <date-time-picker
              :selected-time-window="selectedTimeWindow"
              @onApply="onDateTimePickerApply"
            />
          </gl-form-group>
        </template>

        <gl-form-group
          v-if="hasHeaderButtons"
          label-for="prometheus-graphs-dropdown-buttons"
          class="dropdown-buttons col-md d-md-flex col-lg d-lg-flex align-items-end"
        >
          <div id="prometheus-graphs-dropdown-buttons">
            <gl-button
              v-if="showRearrangePanelsBtn"
              :pressed="isRearrangingPanels"
              variant="default"
              class="mr-2 mt-1 js-rearrange-button"
              @click="toggleRearrangingPanels"
            >
              {{ __('Arrange charts') }}
            </gl-button>
            <gl-button
              v-if="addingMetricsAvailable"
              ref="addMetricBtn"
              v-gl-modal="$options.addMetric.modalId"
              variant="outline-success"
              class="mr-2 mt-1"
            >
              {{ $options.addMetric.title }}
            </gl-button>
            <gl-modal
              v-if="addingMetricsAvailable"
              ref="addMetricModal"
              :modal-id="$options.addMetric.modalId"
              :title="$options.addMetric.title"
            >
              <form ref="customMetricsForm" :action="customMetricsPath" method="post">
                <custom-metrics-form-fields
                  :validate-query-path="validateQueryPath"
                  form-operation="post"
                  @formValidation="setFormValidity"
                />
              </form>
              <div slot="modal-footer">
                <gl-button @click="hideAddMetricModal">{{ __('Cancel') }}</gl-button>
                <gl-button
                  ref="submitCustomMetricsFormBtn"
                  v-track-event="getAddMetricTrackingOptions()"
                  :disabled="!formIsValid"
                  variant="success"
                  @click="submitCustomMetricsForm"
                >
                  {{ __('Save changes') }}
                </gl-button>
              </div>
            </gl-modal>

            <gl-button
              v-if="selectedDashboard.can_edit"
              class="mt-1 js-edit-link"
              :href="selectedDashboard.project_blob_path"
            >
              {{ __('Edit dashboard') }}
            </gl-button>

            <gl-button
              v-if="externalDashboardUrl.length"
              class="mt-1 js-external-dashboard-link"
              variant="primary"
              :href="externalDashboardUrl"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ __('View full dashboard') }}
              <icon name="external-link" />
            </gl-button>
          </div>
        </gl-form-group>
      </div>
    </div>

    <div v-if="!showEmptyState">
      <graph-group
        v-for="(groupData, index) in dashboard.panel_groups"
        :key="`${groupData.group}.${groupData.priority}`"
        :name="groupData.group"
        :show-panels="showPanels"
        :collapse-group="groupHasData(groupData)"
      >
        <vue-draggable
          :value="groupData.panels"
          group="metrics-dashboard"
          :component-data="{ attrs: { class: 'row mx-0 w-100' } }"
          :disabled="!isRearrangingPanels"
          @input="updatePanels(groupData.key, $event)"
        >
          <div
            v-for="(graphData, graphIndex) in groupData.panels"
            :key="`panel-type-${graphIndex}`"
            class="col-12 col-lg-6 px-2 mb-2 draggable"
            :class="{ 'draggable-enabled': isRearrangingPanels }"
          >
            <div class="position-relative draggable-panel js-draggable-panel">
              <div
                v-if="isRearrangingPanels"
                class="draggable-remove js-draggable-remove p-2 w-100 position-absolute d-flex justify-content-end"
                @click="removePanel(groupData.key, groupData.panels, graphIndex)"
              >
                <a class="mx-2 p-2 draggable-remove-link" :aria-label="__('Remove')"
                  ><icon name="close"
                /></a>
              </div>

              <panel-type
                :clipboard-text="generateLink(groupData.group, graphData.title, graphData.y_label)"
                :graph-data="graphData"
                :alerts-endpoint="alertsEndpoint"
                :prometheus-alerts-available="prometheusAlertsAvailable"
                :index="`${index}-${graphIndex}`"
              />
            </div>
          </div>
        </vue-draggable>
      </graph-group>
    </div>
    <empty-state
      v-else
      :selected-state="emptyState"
      :documentation-path="documentationPath"
      :settings-path="settingsPath"
      :clusters-path="clustersPath"
      :empty-getting-started-svg-path="emptyGettingStartedSvgPath"
      :empty-loading-svg-path="emptyLoadingSvgPath"
      :empty-no-data-svg-path="emptyNoDataSvgPath"
      :empty-unable-to-connect-svg-path="emptyUnableToConnectSvgPath"
      :compact="smallEmptyState"
    />
  </div>
</template>
