<script>
import { GlIcon, GlEmptyState, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { mapActions, mapState, mapGetters } from 'vuex';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import { __ } from '~/locale';
import banner from './banner.vue';
import stageCodeComponent from './stage_code_component.vue';
import stageComponent from './stage_component.vue';
import stageNavItem from './stage_nav_item.vue';
import stageReviewComponent from './stage_review_component.vue';
import stageStagingComponent from './stage_staging_component.vue';
import stageTestComponent from './stage_test_component.vue';

const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';

export default {
  name: 'CycleAnalytics',
  components: {
    GlIcon,
    GlEmptyState,
    GlLoadingIcon,
    GlSprintf,
    banner,
    'stage-issue-component': stageComponent,
    'stage-plan-component': stageComponent,
    'stage-code-component': stageCodeComponent,
    'stage-test-component': stageTestComponent,
    'stage-review-component': stageReviewComponent,
    'stage-staging-component': stageStagingComponent,
    'stage-production-component': stageComponent,
    'stage-nav-item': stageNavItem,
    PathNavigation,
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
      return this.selectedStageReady && !this.selectedStage.isUserAllowed;
    },
    selectedStageReady() {
      return !this.isLoadingStage && this.selectedStage;
    },
    emptyStageTitle() {
      return this.selectedStageError
        ? this.selectedStageError
        : __("We don't have enough data to show this stage.");
    },
    emptyStageText() {
      return !this.selectedStageError ? this.selectedStage.emptyStageText : '';
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
      this.fetchCycleAnalyticsData();
    },
    isActiveStage(stage) {
      return stage.slug === this.selectedStage.slug;
    },
    onSelectStage(stage) {
      if (this.isLoadingStage || this.selectedStage?.slug === stage?.slug) return;

      this.setSelectedStage(stage);
      if (!stage.isUserAllowed) {
        return;
      }

      this.fetchStageData();
    },
    dismissOverviewDialog() {
      this.isOverviewDialogDismissed = true;
      Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
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
      <div class="stage-panel-container" data-testid="vsa-stage-table">
        <div class="card stage-panel gl-px-5">
          <div class="card-header border-bottom-0">
            <nav class="col-headers">
              <ul class="gl-display-flex gl-justify-content-space-between gl-list-style-none">
                <li>
                  <span v-if="selectedStage" class="stage-name font-weight-bold">{{
                    selectedStage.legend ? __(selectedStage.legend) : __('Related Issues')
                  }}</span>
                  <span
                    class="has-tooltip"
                    data-placement="top"
                    :title="
                      __('The collection of events added to the data gathered for that stage.')
                    "
                    aria-hidden="true"
                  >
                    <gl-icon name="question-o" class="gl-text-gray-500" />
                  </span>
                </li>
                <li>
                  <span class="stage-name font-weight-bold">{{ __('Time') }}</span>
                  <span
                    class="has-tooltip"
                    data-placement="top"
                    :title="__('The time taken by each data entry gathered by that stage.')"
                    aria-hidden="true"
                  >
                    <gl-icon name="question-o" class="gl-text-gray-500" />
                  </span>
                </li>
              </ul>
            </nav>
          </div>
          <div class="stage-panel-body">
            <section class="stage-events gl-overflow-auto gl-w-full">
              <gl-loading-icon v-if="isLoadingStage" size="lg" />
              <template v-else>
                <gl-empty-state
                  v-if="displayNoAccess"
                  class="js-empty-state"
                  :title="__('You need permission.')"
                  :svg-path="noAccessSvgPath"
                  :description="__('Want to see the data? Please ask an administrator for access.')"
                />
                <template v-else>
                  <gl-empty-state
                    v-if="displayNotEnoughData"
                    class="js-empty-state"
                    :description="emptyStageText"
                    :svg-path="noDataSvgPath"
                    :title="emptyStageTitle"
                  />
                  <component
                    :is="selectedStage.component"
                    v-if="displayStageEvents"
                    :stage="selectedStage"
                    :items="selectedStageEvents"
                    data-testid="stage-table-events"
                  />
                </template>
              </template>
            </section>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
