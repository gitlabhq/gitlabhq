<script>
import { GlIcon, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { mapActions, mapState, mapGetters } from 'vuex';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/cycle_analytics/components/stage_table.vue';
import { __ } from '~/locale';

const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';

export default {
  name: 'CycleAnalytics',
  components: {
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    PathNavigation,
    StageTable,
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
      'startDate',
      'permissions',
    ]),
    ...mapGetters(['pathNavigationData']),
    displayStageEvents() {
      const { selectedStageEvents, isLoadingStage, isEmptyStage } = this;
      return selectedStageEvents.length && !isLoadingStage && !isEmptyStage;
    },
    displayNotEnoughData() {
      return this.selectedStageReady && this.isEmptyStage;
    },
    displayNoAccess() {
      return this.selectedStageReady && !this.isUserAllowed(this.selectedStage.id);
    },
    selectedStageReady() {
      return !this.isLoadingStage && this.selectedStage;
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
  },
  methods: {
    ...mapActions([
      'fetchCycleAnalyticsData',
      'fetchStageData',
      'setSelectedStage',
      'setDateRange',
    ]),
    handleDateSelect(startDate) {
      this.setDateRange({ startDate });
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
  },
};
</script>
<template>
  <div class="cycle-analytics">
    <path-navigation
      v-if="selectedStageReady"
      class="js-path-navigation gl-w-full gl-pb-2"
      :loading="isLoading"
      :stages="pathNavigationData"
      :selected-stage="selectedStage"
      :with-stage-counts="false"
      @selected="onSelectStage"
    />
    <gl-loading-icon v-if="isLoading" size="lg" />
    <div v-else class="wrapper">
      <!--
        We wont have access to the stage counts until we move to a default value stream
        For now we can use the `withStageCounts` flag to ensure we don't display empty stage counts
        Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/326705
      -->
      <div class="card" data-testid="vsa-stage-overview-metrics">
        <div class="card-header">{{ __('Recent Project Activity') }}</div>
        <div class="d-flex justify-content-between">
          <div v-for="item in summary" :key="item.title" class="gl-flex-grow-1 gl-text-center">
            <h3 class="header">{{ item.value }}</h3>
            <p class="text">{{ item.title }}</p>
          </div>
          <div class="flex-grow align-self-center text-center">
            <div class="js-ca-dropdown dropdown inline">
              <!-- eslint-disable-next-line @gitlab/vue-no-data-toggle -->
              <button class="dropdown-menu-toggle" data-toggle="dropdown" type="button">
                <span class="dropdown-label">
                  <gl-sprintf :message="$options.i18n.dropdownText">
                    <template #days>{{ startDate }}</template>
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
      </div>
      <stage-table
        :is-loading="isLoading || isLoadingStage"
        :stage-events="selectedStageEvents"
        :selected-stage="selectedStage"
        :stage-count="null"
        :empty-state-title="emptyStageTitle"
        :empty-state-message="emptyStageText"
        :no-data-svg-path="noDataSvgPath"
        :pagination="null"
      />
    </div>
  </div>
</template>
