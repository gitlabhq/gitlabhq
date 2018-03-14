import $ from 'jquery';

export default () => {
  const $modal = $('#modal-geo-info');

  if (!$modal.length) return;

  $modal
    .appendTo('body')
    .modal({
      modal: true,
      show: false,
    })
    .on('show.bs.modal', (e) => {
      const {
        cloneUrlPrimary,
        cloneUrlSecondary,
      } = $(e.currentTarget).data();

      $('#geo-info-1').text(
        `git clone ${(cloneUrlSecondary || '<clone url for secondary repository>')}`,
      );

      $('#geo-info-2').text(
        `git remote set-url --push origin ${(cloneUrlPrimary || '<clone url for primary repository>')}`,
      );
    });
};
