import $ from 'jquery';
import Vue from 'vue';
import Cookies from 'js-cookie';
import Flash from '../flash';
import Translate from '../vue_shared/translate';
import banner from './components/banner.vue';
import stageCodeComponent from './components/stage_code_component.vue';
import stagePlanComponent from './components/stage_plan_component.vue';
import stageComponent from './components/stage_component.vue';
import stageReviewComponent from './components/stage_review_component.vue';
import stageStagingComponent from './components/stage_staging_component.vue';
import stageTestComponent from './components/stage_test_component.vue';
import CycleAnalyticsService from './cycle_analytics_service';
import CycleAnalyticsStore from './cycle_analytics_store';

Vue.use(Translate);

export default () => {
  const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';

  new Vue({ // eslint-disable-line no-new
    el: '#cycle-analytics',
    name: 'CycleAnalytics',
    components: {
      banner,
      'stage-issue-component': stageComponent,
      'stage-plan-component': stagePlanComponent,
      'stage-code-component': stageCodeComponent,
      'stage-test-component': stageTestComponent,
      'stage-review-component': stageReviewComponent,
      'stage-staging-component': stageStagingComponent,
      'stage-production-component': stageComponent,
    },
    data() {
      const cycleAnalyticsEl = document.querySelector('#cycle-analytics');
      const cycleAnalyticsService = new CycleAnalyticsService({
        requestPath: cycleAnalyticsEl.dataset.requestPath,
      });

      return {
        store: CycleAnalyticsStore,
        state: CycleAnalyticsStore.state,
        isLoading: false,
        isLoadingStage: false,
        isEmptyStage: false,
        hasError: false,
        startDate: 30,
        isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
        service: cycleAnalyticsService,
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
        return new Flash('There was an error while fetching cycle analytics data.');
      },
      initDropdown() {
        const $dropdown = $('.js-ca-dropdown');
        const $label = $dropdown.find('.dropdown-label');

        $dropdown.find('li a').off('click').on('click', (e) => {
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
          .then(resp => resp.json())
          .then((response) => {
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
          })
          .then(resp => resp.json())
          .then((response) => {
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
    },
  });
};
