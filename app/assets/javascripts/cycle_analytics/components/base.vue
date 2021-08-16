<script>
import { GlIcon, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { mapActions, mapState, mapGetters } from 'vuex';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/cycle_analytics/components/stage_table.vue';
import ValueStreamMetrics from '~/cycle_analytics/components/value_stream_metrics.vue';
import { __ } from '~/locale';
import { SUMMARY_METRICS_REQUEST, METRICS_REQUESTS } from '../constants';

const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';

export default {
  name: 'CycleAnalytics',
  components: {
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    PathNavigation,
    StageTable,
    ValueStreamMetrics,
  },
  props: {
    noDataSvgPath: {
      type: String,
      required: true,
    },
    noAccessSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
    };
  },
  computed: {
    ...mapState([
      'isLoading',
      'isLoadingStage',
      'isEmptyStage',
      'selectedStage',
      'selectedStageEvents',
      'selectedStageError',
      'stages',
      'summary',
      'daysInPast',
      'permissions',
      'stageCounts',
      'endpoints',
      'features',
    ]),
    ...mapGetters(['pathNavigationData', 'filterParams']),
    displayStageEvents() {
      const { selectedStageEvents, isLoadingStage, isEmptyStage } = this;
      return selectedStageEvents.length && !isLoadingStage && !isEmptyStage;
    },
    displayNotEnoughData() {
      return !this.isLoadingStage && this.isEmptyStage;
    },
    displayNoAccess() {
      return (
        !this.isLoadingStage && this.selectedStage?.id && !this.isUserAllowed(this.selectedStage.id)
      );
    },
    displayPathNavigation() {
      return this.isLoading || (this.selectedStage && this.pathNavigationData.length);
    },
    emptyStageTitle() {
      if (this.displayNoAccess) {
        return __('You need permission.');
      }
      return this.selectedStageError
        ? this.selectedStageError
        : __("We don't have enough data to show this stage.");
    },
    emptyStageText() {
      if (this.displayNoAccess) {
        return __('Want to see the data? Please ask an administrator for access.');
      }
      return !this.selectedStageError && this.selectedStage?.emptyStageText
        ? this.selectedStage?.emptyStageText
        : '';
    },
    selectedStageCount() {
      if (this.selectedStage) {
        const {
          stageCounts,
          selectedStage: { id },
        } = this;
        return stageCounts[id];
      }
      return 0;
    },
    metricsRequests() {
      return this.features?.cycleAnalyticsForGroups ? METRICS_REQUESTS : SUMMARY_METRICS_REQUEST;
    },
  },
  methods: {
    ...mapActions([
      'fetchCycleAnalyticsData',
      'fetchStageData',
      'setSelectedStage',
      'setDateRange',
    ]),
    handleDateSelect(daysInPast) {
      this.setDateRange(daysInPast);
    },
    onSelectStage(stage) {
      this.setSelectedStage(stage);
    },
    dismissOverviewDialog() {
      this.isOverviewDialogDismissed = true;
      Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
    },
    isUserAllowed(id) {
      const { permissions } = this;
      return Boolean(permissions?.[id]);
    },
  },
  dayRangeOptions: [7, 30, 90],
  i18n: {
    dropdownText: __('Last %{days} days'),
    pageTitle: __('Value Stream Analytics'),
    recentActivity: __('Recent Project Activity'),
  },
};
</script>
<template>
  <div class="cycle-analytics">
    <h3>{{ $options.i18n.pageTitle }}</h3>
    <div class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row">
      <path-navigation
        v-if="displayPathNavigation"
        class="js-path-navigation gl-w-full gl-pb-2"
        :loading="isLoading || isLoadingStage"
        :stages="pathNavigationData"
        :selected-stage="selectedStage"
        @selected="onSelectStage"
      />
      <div class="gl-flex-grow gl-align-self-end">
        <div class="js-ca-dropdown dropdown inline">
          <!-- eslint-disable-next-line @gitlab/vue-no-data-toggle -->
          <button class="dropdown-menu-toggle" data-toggle="dropdown" type="button">
            <span class="dropdown-label">
              <gl-sprintf :message="$options.i18n.dropdownText">
                <template #days>{{ daysInPast }}</template>
              </gl-sprintf>
              <gl-icon name="chevron-down" class="dropdown-menu-toggle-icon gl-top-3" />
            </span>
          </button>
          <ul class="dropdown-menu dropdown-menu-right">
            <li v-for="days in $options.dayRangeOptions" :key="`day-range-${days}`">
              <a href="#" @click.prevent="handleDateSelect(days)">
                <gl-sprintf :message="$options.i18n.dropdownText">
                  <template #days>{{ days }}</template>
                </gl-sprintf>
              </a>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <value-stream-metrics
      :request-path="endpoints.fullPath"
      :request-params="filterParams"
      :requests="metricsRequests"
    />
    <gl-loading-icon v-if="isLoading" size="lg" />
    <stage-table
      v-else
      :is-loading="isLoading || isLoadingStage"
      :stage-events="selectedStageEvents"
      :selected-stage="selectedStage"
      :stage-count="selectedStageCount"
      :empty-state-title="emptyStageTitle"
      :empty-state-message="emptyStageText"
      :no-data-svg-path="noDataSvgPath"
      :pagination="null"
    />
  </div>
</template>
