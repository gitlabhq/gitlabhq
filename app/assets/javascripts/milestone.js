import Flash from './flash';

export default class Milestone {
  constructor() {
    this.bindTabsSwitching();

    // Load merge request tab if it is active
    // merge request tab is active based on different conditions in the backend
    this.loadTab($('.js-milestone-tabs .active a'));

    this.loadInitialTab();
  }

  bindTabsSwitching() {
    return $('a[data-toggle="tab"]').on('show.bs.tab', (e) => {
      const $target = $(e.target);

      location.hash = $target.attr('href');
      this.loadTab($target);
    });
  }
  // eslint-disable-next-line class-methods-use-this
  loadInitialTab() {
    const $target = $(`.js-milestone-tabs a[href="${location.hash}"]`);

    if ($target.length) {
      $target.tab('show');
    }
  }
  // eslint-disable-next-line class-methods-use-this
  loadTab($target) {
    const endpoint = $target.data('endpoint');
    const tabElId = $target.attr('href');

    if (endpoint && !$target.hasClass('is-loaded')) {
      $.ajax({
        url: endpoint,
        dataType: 'JSON',
      })
      .fail(() => new Flash('Error loading milestone tab'))
      .done((data) => {
        $(tabElId).html(data.html);
        $target.addClass('is-loaded');
      });
    }
  }
}
