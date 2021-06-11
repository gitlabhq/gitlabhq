<script>
import { GlButton, GlModalDirective, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import Mousetrap from 'mousetrap';
import VueDraggable from 'vuedraggable';
import { mapActions, mapState, mapGetters } from 'vuex';
import createFlash from '~/flash';
import invalidUrl from '~/lib/utils/invalid_url';
import { ESC_KEY } from '~/lib/utils/keys';
import { mergeUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import AlertsDeprecationWarning from '~/vue_shared/components/alerts_deprecation_warning.vue';
import { defaultTimeRange } from '~/vue_shared/constants';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { metricStates, keyboardShortcutKeys } from '../constants';
import {
  timeRangeFromUrl,
  panelToUrl,
  expandedPanelPayloadFromUrl,
  convertVariablesForURL,
} from '../utils';
import DashboardHeader from './dashboard_header.vue';
import DashboardPanel from './dashboard_panel.vue';

import EmptyState from './empty_state.vue';
import GraphGroup from './graph_group.vue';
import GroupEmptyState from './group_empty_state.vue';
import LinksSection from './links_section.vue';
import VariablesSection from './variables_section.vue';

export default {
  components: {
    AlertsDeprecationWarning,
    VueDraggable,
    DashboardHeader,
    DashboardPanel,
    GlIcon,
    GlButton,
    GraphGroup,
    EmptyState,
    GroupEmptyState,
    VariablesSection,
    LinksSection,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
    TrackEvent: TrackEventDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
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
    defaultBranch: {
      type: String,
      required: false,
      default: '',
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
      selectedTimeRange: timeRangeFromUrl() || defaultTimeRange,
      isRearrangingPanels: false,
      originalDocumentTitle: document.title,
      hoveredPanel: '',
    };
  },
  computed: {
    ...mapState('monitoringDashboard', [
      'dashboard',
      'emptyState',
      'expandedPanel',
      'variables',
      'links',
      'currentDashboard',
      'hasDashboardValidationWarnings',
    ]),
    ...mapGetters('monitoringDashboard', ['selectedDashboard', 'getMetricStates']),
    shouldShowEmptyState() {
      return Boolean(this.emptyState);
    },
    shouldShowVariablesSection() {
      return Boolean(this.variables.length);
    },
    shouldShowLinksSection() {
      return Object.keys(this.links).length > 0;
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
        createFlash({
          message: s__(
            'Metrics|Link contains invalid chart information, please verify the link to see the expanded panel.',
          ),
        });
      }
    },
    expandedPanel: {
      handler({ group, panel }) {
        const dashboardPath = this.currentDashboard || this.selectedDashboard?.path;
        updateHistory({
          url: panelToUrl(dashboardPath, convertVariablesForURL(this.variables), group, panel),
          title: document.title,
        });
      },
      deep: true,
    },
    selectedDashboard(dashboard) {
      this.prependToDocumentTitle(dashboard?.display_name);
    },
    hasDashboardValidationWarnings(hasWarnings) {
      /**
       * This watcher is set for future SPA behaviour of the dashboard
       */
      if (hasWarnings) {
        createFlash({
          message: s__(
            'Metrics|Your dashboard schema is invalid. Edit the dashboard to correct the YAML schema.',
          ),

          type: 'warning',
        });
      }
    },
  },
  created() {
    window.addEventListener('keyup', this.onKeyup);

    Mousetrap.bind(Object.values(keyboardShortcutKeys), this.runShortcut);
  },
  destroyed() {
    window.removeEventListener('keyup', this.onKeyup);

    Mousetrap.unbind(Object.values(keyboardShortcutKeys));
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
      'setGettingStartedEmptyState',
      'setPanelGroupMetrics',
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
    generatePanelUrl(groupKey, panel) {
      const dashboardPath = this.currentDashboard || this.selectedDashboard?.path;
      return panelToUrl(dashboardPath, convertVariablesForURL(this.variables), groupKey, panel);
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
     * Return true if the entire group is loading.
     * @param {String} groupKey - Identifier for group
     * @returns {boolean}
     */
    isGroupLoading(groupKey) {
      return this.groupSingleEmptyState(groupKey) === metricStates.LOADING;
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
    prependToDocumentTitle(text) {
      if (text) {
        document.title = `${text} · ${this.originalDocumentTitle}`;
      }
    },
    onTimeRangeZoom({ start, end }) {
      updateHistory({
        url: mergeUrlParams({ start, end }, window.location.href),
        title: document.title,
      });
      this.selectedTimeRange = { start, end };
      // keep the current dashboard time range
      // in sync with the Vuex store
      this.setTimeRange(this.selectedTimeRange);
    },
    onExpandPanel(group, panel) {
      this.setExpandedPanel({ group, panel });
    },
    onGoBack() {
      this.clearExpandedPanel();
    },
    onKeyup(event) {
      const { key } = event;
      if (key === ESC_KEY) {
        this.clearExpandedPanel();
      }
    },
    onSetRearrangingPanels(isRearrangingPanels) {
      this.isRearrangingPanels = isRearrangingPanels;
    },
    onDateTimePickerInvalid() {
      createFlash({
        message: s__(
          'Metrics|Link contains an invalid time window, please verify the link to see the requested time range.',
        ),
      });
      // As a fallback, switch to default time range instead
      this.selectedTimeRange = defaultTimeRange;
    },
    isPanelHalfWidth(panelIndex, totalPanels) {
      /**
       * A single panel on a row should take the full width of its parent.
       * All others should have half the width their parent.
       */
      const isNumberOfPanelsEven = totalPanels % 2 === 0;
      const isLastPanel = panelIndex === totalPanels - 1;

      return isNumberOfPanelsEven || !isLastPanel;
    },
    /**
     * TODO: Investigate this to utilize the eventBus from Vue
     * The intentation behind this cleanup is to allow for better tests
     * as well as use the correct eventBus facilities that are compatible
     * with Vue 3
     * https://gitlab.com/gitlab-org/gitlab/-/issues/225583
     */
    //
    runShortcut(e) {
      const panel = this.$refs[this.hoveredPanel];

      if (!panel) return;

      const [panelInstance] = panel;
      let actionToRun = '';

      switch (e.key) {
        case keyboardShortcutKeys.EXPAND:
          actionToRun = 'onExpandFromKeyboardShortcut';
          break;

        case keyboardShortcutKeys.VISIT_LOGS:
          actionToRun = 'visitLogsPageFromKeyboardShortcut';
          break;

        case keyboardShortcutKeys.SHOW_ALERT:
          actionToRun = 'showAlertModalFromKeyboardShortcut';
          break;

        case keyboardShortcutKeys.DOWNLOAD_CSV:
          actionToRun = 'downloadCsvFromKeyboardShortcut';
          break;

        case keyboardShortcutKeys.CHART_COPY:
          actionToRun = 'copyChartLinkFromKeyboardShotcut';
          break;

        default:
          actionToRun = 'onExpandFromKeyboardShortcut';
          break;
      }

      panelInstance[actionToRun]();
    },
    setHoveredPanel(groupKey, graphIndex) {
      this.hoveredPanel = `dashboard-panel-${groupKey}-${graphIndex}`;
    },
    clearHoveredPanel() {
      this.hoveredPanel = '';
    },
  },
  i18n: {
    collapsePanelLabel: s__('Metrics|Collapse panel'),
    collapsePanelTooltip: s__('Metrics|Collapse panel (Esc)'),
  },
};
</script>

<template>
  <div class="prometheus-graphs" data-qa-selector="prometheus_graphs">
    <alerts-deprecation-warning v-if="!glFeatures.managedAlertsDeprecation" />

    <dashboard-header
      v-if="showHeader"
      ref="prometheusGraphsHeader"
      class="prometheus-graphs-header d-sm-flex flex-sm-wrap pt-2 pr-1 pb-0 pl-2 border-bottom bg-gray-light"
      :default-branch="defaultBranch"
      :rearrange-panels-available="rearrangePanelsAvailable"
      :custom-metrics-available="customMetricsAvailable"
      :custom-metrics-path="customMetricsPath"
      :validate-query-path="validateQueryPath"
      :is-rearranging-panels="isRearrangingPanels"
      :selected-time-range="selectedTimeRange"
      @dateTimePickerInvalid="onDateTimePickerInvalid"
      @setRearrangingPanels="onSetRearrangingPanels"
    />
    <template v-if="!shouldShowEmptyState">
      <variables-section v-if="shouldShowVariablesSection" />
      <links-section v-if="shouldShowLinksSection" />
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
        <template #top-left>
          <gl-button
            ref="goBackBtn"
            v-gl-tooltip
            class="mr-3 my-3"
            :title="$options.i18n.collapsePanelTooltip"
            @click="onGoBack"
          >
            {{ $options.i18n.collapsePanelLabel }}
          </gl-button>
        </template>
      </dashboard-panel>

      <div v-show="!expandedPanel.panel">
        <graph-group
          v-for="groupData in dashboard.panelGroups"
          :key="`${groupData.group}.${groupData.priority}`"
          :name="groupData.group"
          :show-panels="showPanels"
          :is-loading="isGroupLoading(groupData.key)"
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
              data-testid="dashboard-panel-layout-wrapper"
              class="col-12 px-2 mb-2 draggable"
              :class="{
                'draggable-enabled': isRearrangingPanels,
                'col-lg-6': isPanelHalfWidth(graphIndex, groupData.panels.length),
              }"
              @mouseover="setHoveredPanel(groupData.key, graphIndex)"
              @mouseout="clearHoveredPanel"
            >
              <div class="position-relative draggable-panel js-draggable-panel">
                <div
                  v-if="isRearrangingPanels"
                  class="draggable-remove js-draggable-remove p-2 w-100 position-absolute d-flex justify-content-end"
                  @click="removePanel(groupData.key, groupData.panels, graphIndex)"
                >
                  <a class="mx-2 p-2 draggable-remove-link" :aria-label="__('Remove')">
                    <gl-icon name="close" />
                  </a>
                </div>

                <dashboard-panel
                  :ref="`dashboard-panel-${groupData.key}-${graphIndex}`"
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
    </template>
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
