<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import VueDraggable from 'vuedraggable';
import { GlIcon, GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import DashboardHeader from './dashboard_header.vue';
import DashboardPanel from './dashboard_panel.vue';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import { ESC_KEY, ESC_KEY_IE11 } from '~/lib/utils/keys';
import { mergeUrlParams, updateHistory } from '~/lib/utils/url_utility';
import invalidUrl from '~/lib/utils/invalid_url';
import Icon from '~/vue_shared/components/icon.vue';

import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import GroupEmptyState from './group_empty_state.vue';
import VariablesSection from './variables_section.vue';
import LinksSection from './links_section.vue';

import TrackEventDirective from '~/vue_shared/directives/track_event';
import {
  timeRangeFromUrl,
  panelToUrl,
  expandedPanelPayloadFromUrl,
  convertVariablesForURL,
} from '../utils';
import { metricStates } from '../constants';
import { defaultTimeRange } from '~/vue_shared/constants';

export default {
  components: {
    VueDraggable,
    DashboardHeader,
    DashboardPanel,
    Icon,
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
    defaultBranch: {
      type: String,
      required: true,
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
    };
  },
  computed: {
    ...mapState('monitoringDashboard', [
      'dashboard',
      'emptyState',
      'showEmptyState',
      'expandedPanel',
      'variables',
      'links',
      'currentDashboard',
    ]),
    ...mapGetters('monitoringDashboard', ['selectedDashboard', 'getMetricStates']),
    shouldShowVariablesSection() {
      return Object.keys(this.variables).length > 0;
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
        createFlash(
          s__(
            'Metrics|Link contains invalid chart information, please verify the link to see the expanded panel.',
          ),
        );
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
  },
  created() {
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
    onSetRearrangingPanels(isRearrangingPanels) {
      this.isRearrangingPanels = isRearrangingPanels;
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
  },
  i18n: {
    goBackLabel: s__('Metrics|Go back (Esc)'),
  },
};
</script>

<template>
  <div class="prometheus-graphs" data-qa-selector="prometheus_graphs">
    <dashboard-header
      v-if="showHeader"
      ref="prometheusGraphsHeader"
      class="prometheus-graphs-header d-sm-flex flex-sm-wrap pt-2 pr-1 pb-0 pl-2 border-bottom bg-gray-light"
      :default-branch="defaultBranch"
      :rearrange-panels-available="rearrangePanelsAvailable"
      :custom-metrics-available="customMetricsAvailable"
      :custom-metrics-path="customMetricsPath"
      :validate-query-path="validateQueryPath"
      :external-dashboard-url="externalDashboardUrl"
      :has-metrics="hasMetrics"
      :is-rearranging-panels="isRearrangingPanels"
      :selected-time-range="selectedTimeRange"
      @dateTimePickerInvalid="onDateTimePickerInvalid"
      @setRearrangingPanels="onSetRearrangingPanels"
    />
    <variables-section v-if="shouldShowVariablesSection && !showEmptyState" />
    <links-section v-if="shouldShowLinksSection && !showEmptyState" />
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
