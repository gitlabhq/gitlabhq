import $ from 'jquery';
import Vue from 'vue';
import Cookies from 'js-cookie';
import { GlEmptyState } from '@gitlab/ui';
import filterMixins from 'ee_else_ce/analytics/cycle_analytics/mixins/filter_mixins';
import Flash from '../flash';
import { __ } from '~/locale';
import Translate from '../vue_shared/translate';
import banner from './components/banner.vue';
import stageCodeComponent from './components/stage_code_component.vue';
import stageComponent from './components/stage_component.vue';
import stageReviewComponent from './components/stage_review_component.vue';
import stageStagingComponent from './components/stage_staging_component.vue';
import stageTestComponent from './components/stage_test_component.vue';
import stageNavItem from './components/stage_nav_item.vue';
import CycleAnalyticsService from './cycle_analytics_service';
import CycleAnalyticsStore from './cycle_analytics_store';

Vue.use(Translate);

export default () => {
  const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';
  const cycleAnalyticsEl = document.querySelector('#cycle-analytics');

  // eslint-disable-next-line no-new
  new Vue({
    el: '#cycle-analytics',
    name: 'CycleAnalytics',
    components: {
      GlEmptyState,
      banner,
      'stage-issue-component': stageComponent,
      'stage-plan-component': stageComponent,
      'stage-code-component': stageCodeComponent,
      'stage-test-component': stageTestComponent,
      'stage-review-component': stageReviewComponent,
      'stage-staging-component': stageStagingComponent,
      'stage-production-component': stageComponent,
      GroupsDropdownFilter: () =>
        import('ee_component/analytics/shared/components/groups_dropdown_filter.vue'),
      ProjectsDropdownFilter: () =>
        import('ee_component/analytics/shared/components/projects_dropdown_filter.vue'),
      DateRangeDropdown: () =>
        import('ee_component/analytics/shared/components/date_range_dropdown.vue'),
      'stage-nav-item': stageNavItem,
    },
    mixins: [filterMixins],
    data() {
      return {
        store: CycleAnalyticsStore,
        state: CycleAnalyticsStore.state,
        isLoading: false,
        isLoadingStage: false,
        isEmptyStage: false,
        hasError: false,
        startDate: 30,
        isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
        service: this.createCycleAnalyticsService(cycleAnalyticsEl.dataset.requestPath),
      };
    },
    defaultNumberOfSummaryItems: 3,
    computed: {
      currentStage() {
        return this.store.currentActiveStage();
      },
      summaryTableColumnClass() {
        return this.state.summary.length === this.$options.defaultNumberOfSummaryItems
          ? 'col-sm-3'
          : 'col-sm-4';
      },
    },
    created() {
      // Conditional check placed here to prevent this method from being called on the
      // new Cycle Analytics page (i.e. the new page will be initialized blank and only
      // after a group is selected the cycle analyitcs data will be fetched). Once the
      // old (current) page has been removed this entire created method as well as the
      // variable itself can be completely removed.
      // Follow up issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/64490
      if (cycleAnalyticsEl.dataset.requestPath) this.fetchCycleAnalyticsData();
    },
    methods: {
      handleError() {
        this.store.setErrorState(true);
        return new Flash(__('There was an error while fetching cycle analytics data.'));
      },
      initDropdown() {
        const $dropdown = $('.js-ca-dropdown');
        const $label = $dropdown.find('.dropdown-label');

        $dropdown
          .find('li a')
          .off('click')
          .on('click', e => {
            e.preventDefault();
            const $target = $(e.currentTarget);
            this.startDate = $target.data('value');

            $label.text($target.text().trim());
            this.fetchCycleAnalyticsData({ startDate: this.startDate });
          });
      },
      fetchCycleAnalyticsData(options) {
        const fetchOptions = options || { startDate: this.startDate };

        this.isLoading = true;

        this.service
          .fetchCycleAnalyticsData(fetchOptions)
          .then(response => {
            this.store.setCycleAnalyticsData(response);
            this.selectDefaultStage();
            this.initDropdown();
            this.isLoading = false;
          })
          .catch(() => {
            this.handleError();
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
          .then(response => {
            this.isEmptyStage = !response.events.length;
            this.store.setStageEvents(response.events, stage);
            this.isLoadingStage = false;
          })
          .catch(() => {
            this.isEmptyStage = true;
            this.isLoadingStage = false;
          });
      },
      dismissOverviewDialog() {
        this.isOverviewDialogDismissed = true;
        Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
      },
      createCycleAnalyticsService(requestPath) {
        return new CycleAnalyticsService({
          requestPath,
        });
      },
    },
  });
};
