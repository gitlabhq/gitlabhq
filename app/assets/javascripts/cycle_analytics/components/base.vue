<script>
import { GlIcon, GlEmptyState, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { deprecatedCreateFlash as Flash } from '~/flash';
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
    store: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: this.store.state,
      isLoading: false,
      isLoadingStage: false,
      isEmptyStage: false,
      hasError: true,
      startDate: 30,
      isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
    };
  },
  computed: {
    currentStage() {
      return this.store.currentActiveStage();
    },
  },
  created() {
    this.fetchCycleAnalyticsData();
  },
  methods: {
    handleError() {
      this.store.setErrorState(true);
      return new Flash(__('There was an error while fetching value stream analytics data.'));
    },
    handleDateSelect(startDate) {
      this.startDate = startDate;
      this.fetchCycleAnalyticsData({ startDate: this.startDate });
    },
    fetchCycleAnalyticsData(options) {
      const fetchOptions = options || { startDate: this.startDate };

      this.isLoading = true;

      this.service
        .fetchCycleAnalyticsData(fetchOptions)
        .then((response) => {
          this.store.setCycleAnalyticsData(response);
          this.selectDefaultStage();
        })
        .catch(() => {
          this.handleError();
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    selectDefaultStage() {
      const stage = this.state.stages[0];
      this.selectStage(stage);
    },
    selectStage(stage) {
      if (this.isLoadingStage) return;
      if (this.currentStage === stage) return;

      if (!stage.isUserAllowed) {
        this.store.setActiveStage(stage);
        return;
      }

      this.isLoadingStage = true;
      this.store.setStageEvents([], stage);
      this.store.setActiveStage(stage);

      this.service
        .fetchStageData({
          stage,
          startDate: this.startDate,
          projectIds: this.selectedProjectIds,
        })
        .then((response) => {
          this.isEmptyStage = !response.events.length;
          this.store.setStageEvents(response.events, stage);
        })
        .catch(() => {
          this.isEmptyStage = true;
        })
        .finally(() => {
          this.isLoadingStage = false;
        });
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
    <gl-loading-icon v-if="isLoading" size="lg" />
    <div v-else class="wrapper">
      <div class="card">
        <div class="card-header">{{ __('Recent Project Activity') }}</div>
        <div class="d-flex justify-content-between">
          <div v-for="item in state.summary" :key="item.title" class="flex-grow text-center">
            <h3 class="header">{{ item.value }}</h3>
            <p class="text">{{ item.title }}</p>
          </div>
          <div class="flex-grow align-self-center text-center">
            <div class="js-ca-dropdown dropdown inline">
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
      <div class="stage-panel-container">
        <div class="card stage-panel">
          <div class="card-header border-bottom-0">
            <nav class="col-headers">
              <ul>
                <li class="stage-header pl-5">
                  <span class="stage-name font-weight-bold">{{
                    s__('ProjectLifecycle|Stage')
                  }}</span>
                  <span
                    class="has-tooltip"
                    data-placement="top"
                    :title="__('The phase of the development lifecycle.')"
                    aria-hidden="true"
                  >
                    <gl-icon name="question-o" class="gl-text-gray-500" />
                  </span>
                </li>
                <li class="median-header">
                  <span class="stage-name font-weight-bold">{{ __('Median') }}</span>
                  <span
                    class="has-tooltip"
                    data-placement="top"
                    :title="
                      __(
                        'The value lying at the midpoint of a series of observed values. E.g., between 3, 5, 9, the median is 5. Between 3, 5, 7, 8, the median is (5+7)/2 = 6.',
                      )
                    "
                    aria-hidden="true"
                  >
                    <gl-icon name="question-o" class="gl-text-gray-500" />
                  </span>
                </li>
                <li class="event-header pl-3">
                  <span
                    v-if="currentStage && currentStage.legend"
                    class="stage-name font-weight-bold"
                    >{{ currentStage ? __(currentStage.legend) : __('Related Issues') }}</span
                  >
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
                <li class="total-time-header pr-5 text-right">
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
            <nav class="stage-nav">
              <ul>
                <stage-nav-item
                  v-for="stage in state.stages"
                  :key="stage.title"
                  :title="stage.title"
                  :is-user-allowed="stage.isUserAllowed"
                  :value="stage.value"
                  :is-active="stage.active"
                  @select="selectStage(stage)"
                />
              </ul>
            </nav>
            <section class="stage-events overflow-auto">
              <gl-loading-icon v-show="isLoadingStage" size="lg" />
              <template v-if="currentStage && !currentStage.isUserAllowed">
                <gl-empty-state
                  class="js-empty-state"
                  :title="__('You need permission.')"
                  :svg-path="noAccessSvgPath"
                  :description="__('Want to see the data? Please ask an administrator for access.')"
                />
              </template>
              <template v-else>
                <template v-if="currentStage && isEmptyStage && !isLoadingStage">
                  <gl-empty-state
                    class="js-empty-state"
                    :description="currentStage.emptyStageText"
                    :svg-path="noDataSvgPath"
                    :title="__('We don\'t have enough data to show this stage.')"
                  />
                </template>
                <template v-if="state.events.length && !isLoadingStage && !isEmptyStage">
                  <component
                    :is="currentStage.component"
                    :stage="currentStage"
                    :items="state.events"
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
