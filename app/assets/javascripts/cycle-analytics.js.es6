((global) => {

  gl.CycleAnalytics = class CycleAnalytics {
    constructor() {
      this.vue = new Vue({
        el: '#cycle-analytics',
        name: 'CycleAnalytics',
        created: this.fetchData(),
        data: this.getData({ isLoading: true })
      });
    }

    fetchData() {
      $.get('cycle_analytics.json')
        .done((data) => {
          this.vue.$data = this.getData(data);
          this.initDropdown();
        })
        .error((data) => {
          this.handleError(data);
        })
        .always(() => {
          this.vue.isLoading = false;
        })
    }

    getData(data) {
      return {
        notAvailable: data.notAvailable || false,
        isLoading: data.isLoading || false,
        analytics: {
          summary: [
            { desc: 'New Issues', value: data.issues  || '-' },
            { desc: 'Commits', value: data.commits || '-' },
            { desc: 'Deploys', value: data.deploys || '-' }
          ],
          data: [
            { title: 'Issue', desc: 'Time before an issue get scheduled', value: data.issue || '-' },
            { title: 'Plan', desc: 'Time before an issue starts implementation', value: data.plan || '-' },
            { title: 'Code', desc: 'Time until first merge request', value: data.code || '-' },
            { title: 'Test', desc: 'CI test time of the default branch', value: data.test || '-' },
            { title: 'Review', desc: 'Time between MR creation and merge/close', value: data.review || '-' },
            { title: 'Deploy', desc: 'Time for a new commit to land in one of the environments', value: data.deploy || '-' }
          ]
        }
      }
    }

    handleError(data) {
      // TODO: Make sure that this is the proper error handling
      new Flash('There was an error while fetching cycyle analytics data.', 'alert');
    }

    initDropdown() {
      const $dropdown = $('.js-ca-dropdown');
      const $label = $dropdown.find('.dropdown-label');

      $dropdown.find('li a').on('click', (e) => {
        e.preventDefault();
        const $target = $(e.currentTarget);
        const value = $target.data('value');

        $label.text($target.text().trim());
        this.vue.isLoading = true;
      })
    }
  }

})(window.gl || (window.gl = {}));
