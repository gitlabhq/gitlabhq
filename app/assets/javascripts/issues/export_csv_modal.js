$(() => {
  class ExportCSVModal {
    constructor() {
      this.$el = $('.issues-export-modal');
      this.$btn = $('.csv_download_link');
      this.$close = $('.modal-header .close');
      this.init();
    }

    init() {
      this.$el.modal({ show: false });
      this.$btn.on('click', () => this.$el.modal('show'));
      this.$close.on('click', () => this.$el.modal('hide'));
    }
  }

  window.gl = window.gl || {};
  gl.ExportCSVModal = new ExportCSVModal();
});
