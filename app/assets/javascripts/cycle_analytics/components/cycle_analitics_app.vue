<script>
  import stageComponent from './stage_component.vue';
  import Store from '../cycle_analytics_store';
  import Service from '../cycle_analytics_service';
  import iconCycleAnalyticsSplash from 'icons/icon_cycle_analytics_splash.svg';

  export default {
    name: 'cycleAnaliticsApp',
    components: {
      stageComponent,
    },
    data() {
      const store = new Store();
      const service = new Service();

      return {
        store,
        service,
        state: store.state,
        isLoading: false,
        isLoadingStage: false,
        isEmptyStage: false,
        hasError: false,
        startDate: 30,
        isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
      };
    },
    computed: {
      currentStage() {
        return this.store.currentActiveStage();
      },
      iconCycleAnalyticsSplash() {
        return iconCycleAnalyticsSplash;
      }
    },
    methods: {
      handleError() {
        this.store.setErrorState(true);
        return Flash('There was an error while fetching cycle analytics data.');
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
            this.isLoadingStage = false;
            this.isEmptyStage = true;
          });
      },
      dismissOverviewDialog() {
        this.isOverviewDialogDismissed = true;
        Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
      },
    }
  };
</script>
<template>
  <div>
    <div
      v-if="noData && !isOverviewDialogDismissed"
      class="landing content-block">
        <button
          type="button"
          class="dismiss-button"
          aria-label="Dismiss Cycle Analytics introduction box"
          @click="dismissOverviewDialog">
          <i
            class="fa fa-times"
            aria-hidden="true">
          </i>
        </button>
        <div
          class="svg-container"
          v-html="iconCycleAnalyticsSplash">
        </div>
        <div class="inner-content">
          <h4>
            {{ __('Introducing Cycle Analytics') }}
          </h4>
          <p>
            {{ __('Cycle Analytics gives an overview of how much time it takes to go from idea to production in your project.') }}
          </p>
          <p>
            <a href="TODO" class="btn">
              {{ __('Read more')}}
            </a>
          </p>
        </div>
    </div>
    <div v-if="!isLoading && !hasError && !noData" class="wrapper">
      <div class="panel panel-default">
        <div class="panel-heading">
          {{ __('Pipeline Health') }}
        </div>
        <div class="content-block">
          <div class="container-fluid">
            <div class="row">
              <div
                class="col-sm-3 col-xs-12 column"
                v-for="(item, i) in state.summary"
                :key="i">
                <h3 class="header">
                  {{item.value}}
                </h3>
                <p class="text">
                  {{item.title}}
                </p>
              </div>
              <div class="col-sm-3 col-xs-12 column">
                <div class="dropdown inline js-ca-dropdown">
                  <button
                    type="button"
                    data-toggle="dropdown"
                    class="dropdown-menu-toggle">
                    <span class="dropdown-label">
                      {{ n__('Last %d day', 'Last %d days', 30) }}
                    </span>
                    <i
                      class="fa fa-chevron-down"
                      aria-hidden="true">
                    </i>
                  </button>
                  <ul class="dropdown-menu dropdowm-menu-align-right">
                    <li>
                      <a href="#" data-value="7">
                        {{ n__('Last %d day', 'Last %d days', 7) }}
                      </a>
                    </li>
                    <li>
                      <a href="#" data-value="30">
                        {{ n__('Last %d day', 'Last %d days', 30) }}
                      </a>
                    </li>
                    <li>
                      <a href="#" data-value="90">
                        {{ n__('Last %d day', 'Last %d days', 90) }}
                      </a>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="stage-pane-container">
        <div class="panel panel-default stage-panel">
          <div class="panel-heading">
            <div class="nav col-headers">
              <ul>
                <li class="stage-header">
                  <span class="stage-name">
                    {{s__('ProjectLifecycle|Stage')}}
                  </span>
                  <i
                    class="fa fa-question-circle"
                    v-tooltip
                    :title="_("The phase of the development lifecycle.")"
                    data-placement="top"
                    aria-hidden="true">
                  </i>
                </li>
                <li class="median-header">
                  <span class="stage-name">
                    {{ __('Median') }}
                  </span>
                  <i
                    class="fa fa-question-circle"
                    v-tooltip
                    :title="_("The value lying at the midpoint of a series of observed values. E.g., between 3, 5, 9, the median is 5. Between 3, 5, 7, 8, the median is (5+7)/2 = 6.")"
                    data-placement="top"
                    aria-hidden="true">
                  </i>
                </li>
                <li class="event-header">
                  <span class="stage-name">
                    {{ currentStage ? __(currentStage.legend) : __('Related Issues') }}
                  </span>
                  <i
                    class="fa fa-question-circle"
                    v-tooltip
                    :title="_("The collection of events added to the data gathered for that stage.")"
                    data-placement="top"
                    aria-hidden="true">
                  </i>
                </li>
                <li class="total-time-header">
                  <span class="stage-name">
                    {{ __('Total Time') }}
                  </span>
                  <i
                    class="fa fa-question-circle"
                    v-tooltip
                    :title="_("The time taken by each data entry gathered by that stage.")"
                    data-placement="top"
                    aria-hidden="true">
                  </i>
                </li>
              </ul>
            </div>
          </div>
          <div class="stage-panel-body">
            <div class="nav stage-nav">
              <ul>
                <li
                  class="stage-nav-item"
                  :class="{ active: stage.active }"
                  @click="selectStage(stage)"
                  v-for="(stage, i) in stage.stages">
                  <div class="stage-nav-item-cell stage-name">
                    {{ stage.title }}
                  </div>
                  <div class="stage-nav-item-cell stage-median">

                  </div>
                  </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
