<script>
import { debounce } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import VueDraggable from 'vuedraggable';
import {
  GlIcon,
  GlButton,
  GlDeprecatedButton,
  GlDropdown,
  GlDropdownItem,
  GlDropdownHeader,
  GlDropdownDivider,
  GlModal,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import DashboardPanel from './dashboard_panel.vue';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import { ESC_KEY, ESC_KEY_IE11 } from '~/lib/utils/keys';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import { mergeUrlParams, redirectTo, updateHistory } from '~/lib/utils/url_utility';
import invalidUrl from '~/lib/utils/invalid_url';
import Icon from '~/vue_shared/components/icon.vue';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';

import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import GroupEmptyState from './group_empty_state.vue';
import DashboardsDropdown from './dashboards_dropdown.vue';

import TrackEventDirective from '~/vue_shared/directives/track_event';
import {
  getAddMetricTrackingOptions,
  timeRangeToUrl,
  timeRangeFromUrl,
  panelToUrl,
  expandedPanelPayloadFromUrl,
} from '../utils';
import { metricStates } from '../constants';
import { defaultTimeRange, timeRanges } from '~/vue_shared/constants';

export default {
  components: {
    VueDraggable,
    DashboardPanel,
    Icon,
    GlIcon,
    GlButton,
    GlDeprecatedButton,
    GlDropdown,
    GlLoadingIcon,
    GlDropdownItem,
    GlDropdownHeader,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlModal,
    CustomMetricsFormFields,

    DateTimePicker,
    GraphGroup,
    EmptyState,
    GroupEmptyState,
    DashboardsDropdown,
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
    showHeader: {
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
    logsPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    defaultBranch: {
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
    emptyNoDataSmallSvgPath: {
      type: String,
      required: true,
    },
    emptyUnableToConnectSvgPath: {
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
    dashboardsEndpoint: {
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
      formIsValid: null,
      selectedTimeRange: timeRangeFromUrl() || defaultTimeRange,
      hasValidDates: true,
      timeRanges,
      isRearrangingPanels: false,
    };
  },
  computed: {
    ...mapState('monitoringDashboard', [
      'dashboard',
      'emptyState',
      'showEmptyState',
      'useDashboardEndpoint',
      'allDashboards',
      'environmentsLoading',
      'expandedPanel',
    ]),
    ...mapGetters('monitoringDashboard', ['getMetricStates', 'filteredEnvironments']),
    firstDashboard() {
      return this.allDashboards.length > 0 ? this.allDashboards[0] : {};
    },
    selectedDashboard() {
      return this.allDashboards.find(d => d.path === this.currentDashboard) || this.firstDashboard;
    },
    showRearrangePanelsBtn() {
      return !this.showEmptyState && this.rearrangePanelsAvailable;
    },
    addingMetricsAvailable() {
      return (
        this.customMetricsAvailable &&
        !this.showEmptyState &&
        this.firstDashboard === this.selectedDashboard
      );
    },
    shouldShowEnvironmentsDropdownNoMatchedMsg() {
      return !this.environmentsLoading && this.filteredEnvironments.length === 0;
    },
  },
  watch: {
    dashboard(newDashboard) {
      try {
        const expandedPanel = expandedPanelPayloadFromUrl(newDashboard);
        if (expandedPanel) {
          this.setExpandedPanel(expandedPanel);
        }
      } catch {
        createFlash(
          s__(
            'Metrics|Link contains invalid chart information, please verify the link to see the expanded panel.',
          ),
        );
      }
    },
  },

  created() {
    this.setInitialState({
      metricsEndpoint: this.metricsEndpoint,
      deploymentsEndpoint: this.deploymentsEndpoint,
      dashboardEndpoint: this.dashboardEndpoint,
      dashboardsEndpoint: this.dashboardsEndpoint,
      currentDashboard: this.currentDashboard,
      projectPath: this.projectPath,
      logsPath: this.logsPath,
      currentEnvironmentName: this.currentEnvironmentName,
    });
    window.addEventListener('keyup', this.onKeyup);
  },
  destroyed() {
    window.removeEventListener('keyup', this.onKeyup);
  },
  mounted() {
    if (!this.hasMetrics) {
      this.setGettingStartedEmptyState();
    } else {
      this.setTimeRange(this.selectedTimeRange);
      this.fetchData();
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', [
      'setTimeRange',
      'fetchData',
      'fetchDashboardData',
      'setGettingStartedEmptyState',
      'setInitialState',
      'setPanelGroupMetrics',
      'filterEnvironments',
      'setExpandedPanel',
      'clearExpandedPanel',
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

    onDateTimePickerInput(timeRange) {
      redirectTo(timeRangeToUrl(timeRange));
    },
    onDateTimePickerInvalid() {
      createFlash(
        s__(
          'Metrics|Link contains an invalid time window, please verify the link to see the requested time range.',
        ),
      );
      // As a fallback, switch to default time range instead
      this.selectedTimeRange = defaultTimeRange;
    },
    generatePanelUrl(groupKey, panel) {
      const dashboardPath = this.currentDashboard || this.firstDashboard.path;
      return panelToUrl(dashboardPath, groupKey, panel);
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
    debouncedEnvironmentsSearch: debounce(function environmentsSearchOnInput(searchTerm) {
      this.filterEnvironments(searchTerm);
    }, 500),
    submitCustomMetricsForm() {
      this.$refs.customMetricsForm.submit();
    },
    /**
     * Return a single empty state for a group.
     *
     * If all states are the same a single state is returned to be displayed
     * Except if the state is OK, in which case the group is displayed.
     *
     * @param {String} groupKey - Identifier for group
     * @returns {String} state code from `metricStates`
     */
    groupSingleEmptyState(groupKey) {
      const states = this.getMetricStates(groupKey);
      if (states.length === 1 && states[0] !== metricStates.OK) {
        return states[0];
      }
      return null;
    },
    /**
     * A group should be not collapsed if any metric is loaded (OK)
     *
     * @param {String} groupKey - Identifier for group
     * @returns {Boolean} If the group should be collapsed
     */
    collapseGroup(groupKey) {
      // Collapse group if no data is available
      return !this.getMetricStates(groupKey).includes(metricStates.OK);
    },
    getAddMetricTrackingOptions,

    selectDashboard(dashboard) {
      const params = {
        dashboard: dashboard.path,
      };
      redirectTo(mergeUrlParams(params, window.location.href));
    },

    refreshDashboard() {
      this.fetchDashboardData();
    },

    onTimeRangeZoom({ start, end }) {
      updateHistory({
        url: mergeUrlParams({ start, end }, window.location.href),
        title: document.title,
      });
      this.selectedTimeRange = { start, end };
    },
    onExpandPanel(group, panel) {
      this.setExpandedPanel({ group, panel });
    },
    onGoBack() {
      this.clearExpandedPanel();
    },
    onKeyup(event) {
      const { key } = event;
      if (key === ESC_KEY || key === ESC_KEY_IE11) {
        this.clearExpandedPanel();
      }
    },
  },
  addMetric: {
    title: s__('Metrics|Add metric'),
    modalId: 'add-metric',
  },
  i18n: {
    goBackLabel: s__('Metrics|Go back (Esc)'),
  },
};
</script>

<template>
  <div class="prometheus-graphs" data-qa-selector="prometheus_graphs">
    <div
      v-if="showHeader"
      ref="prometheusGraphsHeader"
      class="prometheus-graphs-header d-sm-flex flex-sm-wrap pt-2 pr-1 pb-0 pl-2 border-bottom bg-gray-light"
    >
      <div class="mb-2 pr-2 d-flex d-sm-block">
        <dashboards-dropdown
          id="monitor-dashboards-dropdown"
          data-qa-selector="dashboards_filter_dropdown"
          class="flex-grow-1"
          toggle-class="dropdown-menu-toggle"
          :default-branch="defaultBranch"
          :selected-dashboard="selectedDashboard"
          @selectDashboard="selectDashboard($event)"
        />
      </div>

      <div class="mb-2 pr-2 d-flex d-sm-block">
        <gl-dropdown
          id="monitor-environments-dropdown"
          ref="monitorEnvironmentsDropdown"
          class="flex-grow-1"
          data-qa-selector="environments_dropdown"
          toggle-class="dropdown-menu-toggle"
          menu-class="monitor-environment-dropdown-menu"
          :text="currentEnvironmentName"
        >
          <div class="d-flex flex-column overflow-hidden">
            <gl-dropdown-header class="monitor-environment-dropdown-header text-center">
              {{ __('Environment') }}
            </gl-dropdown-header>
            <gl-dropdown-divider />
            <gl-search-box-by-type
              ref="monitorEnvironmentsDropdownSearch"
              class="m-2"
              @input="debouncedEnvironmentsSearch"
            />
            <gl-loading-icon
              v-if="environmentsLoading"
              ref="monitorEnvironmentsDropdownLoading"
              :inline="true"
            />
            <div v-else class="flex-fill overflow-auto">
              <gl-dropdown-item
                v-for="environment in filteredEnvironments"
                :key="environment.id"
                :active="environment.name === currentEnvironmentName"
                active-class="is-active"
                :href="environment.metrics_path"
                >{{ environment.name }}</gl-dropdown-item
              >
            </div>
            <div
              v-show="shouldShowEnvironmentsDropdownNoMatchedMsg"
              ref="monitorEnvironmentsDropdownMsg"
              class="text-secondary no-matches-message"
            >
              {{ __('No matching results') }}
            </div>
          </div>
        </gl-dropdown>
      </div>

      <div class="mb-2 pr-2 d-flex d-sm-block">
        <date-time-picker
          ref="dateTimePicker"
          class="flex-grow-1 show-last-dropdown"
          data-qa-selector="show_last_dropdown"
          :value="selectedTimeRange"
          :options="timeRanges"
          @input="onDateTimePickerInput"
          @invalid="onDateTimePickerInvalid"
        />
      </div>

      <div class="mb-2 pr-2 d-flex d-sm-block">
        <gl-deprecated-button
          ref="refreshDashboardBtn"
          v-gl-tooltip
          class="flex-grow-1"
          variant="default"
          :title="s__('Metrics|Refresh dashboard')"
          @click="refreshDashboard"
        >
          <icon name="retry" />
        </gl-deprecated-button>
      </div>

      <div class="flex-grow-1"></div>

      <div class="d-sm-flex">
        <div v-if="showRearrangePanelsBtn" class="mb-2 mr-2 d-flex">
          <gl-deprecated-button
            :pressed="isRearrangingPanels"
            variant="default"
            class="flex-grow-1 js-rearrange-button"
            @click="toggleRearrangingPanels"
          >
            {{ __('Arrange charts') }}
          </gl-deprecated-button>
        </div>
        <div v-if="addingMetricsAvailable" class="mb-2 mr-2 d-flex d-sm-block">
          <gl-deprecated-button
            ref="addMetricBtn"
            v-gl-modal="$options.addMetric.modalId"
            variant="outline-success"
            data-qa-selector="add_metric_button"
            class="flex-grow-1"
          >
            {{ $options.addMetric.title }}
          </gl-deprecated-button>
          <gl-modal
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
              <gl-deprecated-button @click="hideAddMetricModal">
                {{ __('Cancel') }}
              </gl-deprecated-button>
              <gl-deprecated-button
                ref="submitCustomMetricsFormBtn"
                v-track-event="getAddMetricTrackingOptions()"
                :disabled="!formIsValid"
                variant="success"
                @click="submitCustomMetricsForm"
              >
                {{ __('Save changes') }}
              </gl-deprecated-button>
            </div>
          </gl-modal>
        </div>

        <div v-if="selectedDashboard.can_edit" class="mb-2 mr-2 d-flex d-sm-block">
          <gl-deprecated-button
            class="flex-grow-1 js-edit-link"
            :href="selectedDashboard.project_blob_path"
            data-qa-selector="edit_dashboard_button"
          >
            {{ __('Edit dashboard') }}
          </gl-deprecated-button>
        </div>

        <div v-if="externalDashboardUrl.length" class="mb-2 mr-2 d-flex d-sm-block">
          <gl-deprecated-button
            class="flex-grow-1 js-external-dashboard-link"
            variant="primary"
            :href="externalDashboardUrl"
            target="_blank"
            rel="noopener noreferrer"
          >
            {{ __('View full dashboard') }} <icon name="external-link" />
          </gl-deprecated-button>
        </div>
      </div>
    </div>

    <div v-if="!showEmptyState">
      <dashboard-panel
        v-show="expandedPanel.panel"
        ref="expandedPanel"
        :settings-path="settingsPath"
        :clipboard-text="generatePanelUrl(expandedPanel.group, expandedPanel.panel)"
        :graph-data="expandedPanel.panel"
        :alerts-endpoint="alertsEndpoint"
        :height="600"
        :prometheus-alerts-available="prometheusAlertsAvailable"
        @timerangezoom="onTimeRangeZoom"
      >
        <template #topLeft>
          <gl-button
            ref="goBackBtn"
            v-gl-tooltip
            class="mr-3 my-3"
            :title="$options.i18n.goBackLabel"
            @click="onGoBack"
          >
            <gl-icon
              name="arrow-left"
              :aria-label="$options.i18n.goBackLabel"
              class="text-secondary"
            />
          </gl-button>
        </template>
      </dashboard-panel>

      <div v-show="!expandedPanel.panel">
        <graph-group
          v-for="groupData in dashboard.panelGroups"
          :key="`${groupData.group}.${groupData.priority}`"
          :name="groupData.group"
          :show-panels="showPanels"
          :collapse-group="collapseGroup(groupData.key)"
        >
          <vue-draggable
            v-if="!groupSingleEmptyState(groupData.key)"
            :value="groupData.panels"
            group="metrics-dashboard"
            :component-data="{ attrs: { class: 'row mx-0 w-100' } }"
            :disabled="!isRearrangingPanels"
            @input="updatePanels(groupData.key, $event)"
          >
            <div
              v-for="(graphData, graphIndex) in groupData.panels"
              :key="`dashboard-panel-${graphIndex}`"
              class="col-12 col-lg-6 px-2 mb-2 draggable"
              :class="{ 'draggable-enabled': isRearrangingPanels }"
            >
              <div class="position-relative draggable-panel js-draggable-panel">
                <div
                  v-if="isRearrangingPanels"
                  class="draggable-remove js-draggable-remove p-2 w-100 position-absolute d-flex justify-content-end"
                  @click="removePanel(groupData.key, groupData.panels, graphIndex)"
                >
                  <a class="mx-2 p-2 draggable-remove-link" :aria-label="__('Remove')">
                    <icon name="close" />
                  </a>
                </div>

                <dashboard-panel
                  :settings-path="settingsPath"
                  :clipboard-text="generatePanelUrl(groupData.group, graphData)"
                  :graph-data="graphData"
                  :alerts-endpoint="alertsEndpoint"
                  :prometheus-alerts-available="prometheusAlertsAvailable"
                  @timerangezoom="onTimeRangeZoom"
                  @expand="onExpandPanel(groupData.group, graphData)"
                />
              </div>
            </div>
          </vue-draggable>
          <div v-else class="py-5 col col-sm-10 col-md-8 col-lg-7 col-xl-6">
            <group-empty-state
              ref="empty-group"
              :documentation-path="documentationPath"
              :settings-path="settingsPath"
              :selected-state="groupSingleEmptyState(groupData.key)"
              :svg-path="emptyNoDataSmallSvgPath"
            />
          </div>
        </graph-group>
      </div>
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
      :empty-no-data-small-svg-path="emptyNoDataSmallSvgPath"
      :empty-unable-to-connect-svg-path="emptyUnableToConnectSvgPath"
      :compact="smallEmptyState"
    />
  </div>
</template>
