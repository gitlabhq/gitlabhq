import 'vendor/peek';
import 'vendor/peek.performance_bar';

export default class PerformanceBar {
  constructor(opts) {
    if (!PerformanceBar.singleton) {
      this.init(opts);
      PerformanceBar.singleton = this;
    }
    return PerformanceBar.singleton;
  }

  init(opts) {
    const $container = $(opts.container);
    this.$sqlProfileLink = $container.find('.js-toggle-modal-peek-sql');
    this.$sqlProfileModal = $container.find('#modal-peek-pg-queries');
    this.$lineProfileLink = $container.find('.js-toggle-modal-peek-line-profile');
    this.$lineProfileModal = $('#modal-peek-line-profile');
    this.initEventListeners();
    this.showModalOnLoad();
  }

  initEventListeners() {
    this.$sqlProfileLink.on('click', () => this.handleSQLProfileLink());
    this.$lineProfileLink.on('click', e => this.handleLineProfileLink(e));
    $(document).on('click', '.js-lineprof-file', PerformanceBar.toggleLineProfileFile);
  }

  showModalOnLoad() {
    // When a lineprofiler query-string param is present, we show the line
    // profiler modal upon page load
    if (/lineprofiler/.test(window.location.search)) {
      PerformanceBar.toggleModal(this.$lineProfileModal);
    }
  }

  handleSQLProfileLink() {
    PerformanceBar.toggleModal(this.$sqlProfileModal);
  }

  handleLineProfileLink(e) {
    const lineProfilerParameter = gl.utils.getParameterValues('lineprofiler');
    const lineProfilerParameterRegex = new RegExp(`lineprofiler=${lineProfilerParameter[0]}`);
    const shouldToggleModal = lineProfilerParameter.length > 0 &&
      lineProfilerParameterRegex.test(e.currentTarget.href);

    if (shouldToggleModal) {
      e.preventDefault();
      PerformanceBar.toggleModal(this.$lineProfileModal);
    }
  }

  static toggleModal($modal) {
    if ($modal.length) {
      $modal.modal('toggle');
    }
  }

  static toggleLineProfileFile(e) {
    $(e.currentTarget).parents('.peek-rblineprof-file').find('.data').toggle();
  }
}
