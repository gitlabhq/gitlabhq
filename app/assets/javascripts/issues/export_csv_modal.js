/* eslint-disable no-new */

$(() => {
  class ExportCSVModal {
    constructor() {
      this.$modal = $('.issues-export-modal');
      this.$downloadBtn = $('.csv_download_link');
      this.$closeBtn = $('.modal-header .close');
      this.init();
    }

    init() {
      this.$modal.modal({ show: false });
      this.$downloadBtn.on('click', () => this.$modal.modal('show'));
      this.$closeBtn.on('click', () => this.$modal.modal('hide'));
    }
  }

  new ExportCSVModal();
});
