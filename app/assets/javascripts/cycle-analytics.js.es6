((global) => {

  const COOKIE_NAME = 'cycle_analytics_help_dismissed';

  gl.CycleAnalytics = class CycleAnalytics {
    constructor() {
      const that = this;

      this.isHelpDismissed = $.cookie(COOKIE_NAME);
      this.vue = new Vue({
        el: '#cycle-analytics',
        name: 'CycleAnalytics',
        created: this.fetchData(),
        data: this.decorateData({ isLoading: true }),
        methods: {
          dismissLanding() {
            that.dismissLanding();
          }
        }
      });
    }

    fetchData(options) {
      options = options || { startDate: 30 };

      $.ajax({
        url: $('#cycle-analytics').data('request-path'),
        method: 'GET',
        dataType: 'json',
        contentType: 'application/json',
        data: { start_date: options.startDate }
      }).done((data) => {
        this.vue.$data = this.decorateData(data);
        this.initDropdown();
      })
      .error((data) => {
        this.handleError(data);
      })
      .always(() => {
        this.vue.isLoading = false;
      })
    }

    decorateData(data) {
      data.summary = data.summary || [];
      data.stats = data.stats || [];
      data.isHelpDismissed = this.isHelpDismissed;
      data.isLoading = data.isLoading || false;

      data.summary.forEach((item) => {
        item.value = item.value || '-';
      });

      data.stats.forEach((item) => {
        item.value = item.value || '- - -';
      })

      return data;
    }

    handleError(data) {
      this.vue.$data = {
        hasError: true,
        isHelpDismissed: this.isHelpDismissed
      };

      new Flash('There was an error while fetching cycle analytics data.', 'alert');
    }

    dismissLanding() {
      this.vue.isHelpDismissed = true;
      $.cookie(COOKIE_NAME, true);
    }

    initDropdown() {
      const $dropdown = $('.js-ca-dropdown');
      const $label = $dropdown.find('.dropdown-label');

      $dropdown.find('li a').off('click').on('click', (e) => {
        e.preventDefault();
        const $target = $(e.currentTarget);
        const value = $target.data('value');

        $label.text($target.text().trim());
        this.vue.isLoading = true;
        this.fetchData({ startDate: value });
      })
    }

  }

})(window.gl || (window.gl = {}));
