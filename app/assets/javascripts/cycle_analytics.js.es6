//= require vue

((global) => {

  const COOKIE_NAME = 'cycle_analytics_help_dismissed';
  const store = gl.cycleAnalyticsStore = {
    isLoading: true,
    hasError: false,
    isHelpDismissed: $.cookie(COOKIE_NAME),
    analytics: {}
  };

  gl.CycleAnalytics = class CycleAnalytics {
    constructor() {
      const that = this;

      this.vue = new Vue({
        el: '#cycle-analytics',
        name: 'CycleAnalytics',
        created: this.fetchData(),
        data: store,
        methods: {
          dismissLanding() {
            that.dismissLanding();
          }
        }
      });
    }

    fetchData(options) {
      store.isLoading = true;
      options = options || { startDate: 30 };

      $.ajax({
        url: $('#cycle-analytics').data('request-path'),
        method: 'GET',
        dataType: 'json',
        contentType: 'application/json',
        data: { start_date: options.startDate }
      }).done((data) => {
        this.decorateData(data);
        this.initDropdown();
      })
      .error((data) => {
        this.handleError(data);
      })
      .always(() => {
        store.isLoading = false;
      })
    }

    decorateData(data) {
      data.summary = data.summary || [];
      data.stats = data.stats || [];

      data.summary.forEach((item) => {
        item.value = item.value || '-';
      });

      data.stats.forEach((item) => {
        item.value = item.value || '- - -';
      });

      store.analytics = data;
    }

    handleError(data) {
      store.hasError = true;
      new Flash('There was an error while fetching cycle analytics data.', 'alert');
    }

    dismissLanding() {
      store.isHelpDismissed = true;
      $.cookie(COOKIE_NAME, true, {
        path: gon.relative_url_root || '/'
      });
    }

    initDropdown() {
      const $dropdown = $('.js-ca-dropdown');
      const $label = $dropdown.find('.dropdown-label');

      $dropdown.find('li a').off('click').on('click', (e) => {
        e.preventDefault();
        const $target = $(e.currentTarget);
        const value = $target.data('value');

        $label.text($target.text().trim());
        this.fetchData({ startDate: value });
      })
    }

  }

})(window.gl || (window.gl = {}));
