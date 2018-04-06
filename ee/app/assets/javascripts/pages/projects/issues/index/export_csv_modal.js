import $ from 'jquery';

export default function initExportCSVModal() {
  const $modal = $('.issues-export-modal');
  const $downloadBtn = $('.csv_download_link');
  const $closeBtn = $('.modal-header .close');

  $modal.modal({ show: false });
  $downloadBtn.on('click', () => $modal.modal('show'));
  $closeBtn.on('click', () => $modal.modal('hide'));
}
