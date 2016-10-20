//= require vue
//= require_tree .

$(() => {

  const cycleAnalyticsEl = document.querySelector('#cycle-analytics');
  const cycleAnalyticsStore = gl.cycleAnalytics.CycleAnalyticsStore;
  const cycleAnalyticsService = new gl.cycleAnalytics.CycleAnalyticsService({
    requestPath: cycleAnalyticsEl.dataset.requestPath
  })

  gl.cycleAnalyticsApp = new Vue({
    el: '#cycle-analytics',
    name: 'CycleAnalytics',
    data: cycleAnalyticsStore.state,
    created() {
      this.fetchCycleAnalyticsData();
    },
    methods: {
      handleError(data) {
        cycleAnalyticsStore.setErrorState(true);
        new Flash('There was an error while fetching cycle analytics data.');
      },
      initDropdown() {
        const $dropdown = $('.js-ca-dropdown');
        const $label = $dropdown.find('.dropdown-label');

        $dropdown.find('li a').off('click').on('click', (e) => {
          e.preventDefault();
          const $target = $(e.currentTarget);
          const value = $target.data('value');

          $label.text($target.text().trim());
          this.fetchCycleAnalyticsData({ startDate: value });
        });
      },
      fetchCycleAnalyticsData(options) {
        options = options || { startDate: 30 };

        cycleAnalyticsStore.setLoadingState(true);

        cycleAnalyticsService
          .fetchCycleAnalyticsData(options)
          .then((response) => {
            cycleAnalyticsStore.setCycleAnalyticsData(response);
            this.initDropdown();
          })
          .fail(() => {
            this.handleError(data);
          })
          .always(() => {
            cycleAnalyticsStore.setLoadingState(false);
          });
      }
    }
  });
});
