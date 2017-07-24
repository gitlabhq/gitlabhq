document.addEventListener('DOMContentLoaded', () => {
  const modal = $('#modal_merge_info').modal({
    modal: true,
    show: false,
  });
  $('.how_to_merge_link').bind('click', () => {
    modal.show();
  });
  $('.modal-header .close').bind('click', () => {
    modal.hide();
  });
});
