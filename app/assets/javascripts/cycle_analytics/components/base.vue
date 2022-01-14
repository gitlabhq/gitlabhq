<script>
import { GlLoadingIcon } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { mapActions, mapState, mapGetters } from 'vuex';
import { toYmd } from '~/analytics/shared/utils';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/cycle_analytics/components/stage_table.vue';
import ValueStreamFilters from '~/cycle_analytics/components/value_stream_filters.vue';
import ValueStreamMetrics from '~/cycle_analytics/components/value_stream_metrics.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { __ } from '~/locale';
import { SUMMARY_METRICS_REQUEST, METRICS_REQUESTS } from '../constants';

const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';

export default {
  name: 'CycleAnalytics',
  components: {
    GlLoadingIcon,
    PathNavigation,
    StageTable,
    ValueStreamFilters,
    ValueStreamMetrics,
    UrlSync,
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
      'permissions',
      'stageCounts',
      'endpoints',
      'features',
      'createdBefore',
      'createdAfter',
      'pagination',
    ]),
    ...mapGetters(['pathNavigationData', 'filterParams']),
    isLoaded() {
      return !this.isLoading && !this.isLoadingStage;
    },
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
    query() {
      return {
        created_after: toYmd(this.createdAfter),
        created_before: toYmd(this.createdBefore),
        stage_id: this.selectedStage?.id || null,
        sort: this.pagination?.sort || null,
        direction: this.pagination?.direction || null,
        page: this.pagination?.page || null,
      };
    },
  },
  methods: {
    ...mapActions([
      'fetchStageData',
      'setSelectedStage',
      'setDateRange',
      'updateStageTablePagination',
    ]),
    onSetDateRange({ startDate, endDate }) {
      this.setDateRange({
        createdAfter: new Date(startDate),
        createdBefore: new Date(endDate),
      });
    },
    onSelectStage(stage) {
      this.setSelectedStage(stage);
      this.updateStageTablePagination({ ...this.pagination, page: 1 });
    },
    dismissOverviewDialog() {
      this.isOverviewDialogDismissed = true;
      Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
    },
    isUserAllowed(id) {
      const { permissions } = this;
      return Boolean(permissions?.[id]);
    },
    onHandleUpdatePagination(data) {
      this.updateStageTablePagination(data);
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
  <div>
    <h3>{{ $options.i18n.pageTitle }}</h3>
    <div class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row">
      <path-navigation
        v-if="displayPathNavigation"
        data-testid="vsa-path-navigation"
        class="gl-w-full gl-pb-2"
        :loading="isLoading || isLoadingStage"
        :stages="pathNavigationData"
        :selected-stage="selectedStage"
        @selected="onSelectStage"
      />
    </div>
    <value-stream-filters
      :group-id="endpoints.groupId"
      :group-path="endpoints.groupPath"
      :has-project-filter="false"
      :start-date="createdAfter"
      :end-date="createdBefore"
      @setDateRange="onSetDateRange"
    />
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
      :pagination="pagination"
      @handleUpdatePagination="onHandleUpdatePagination"
    />
    <url-sync v-if="isLoaded" :query="query" />
  </div>
</template>
