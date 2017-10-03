export default () => {
  $('.fork-thumbnail a').on('click', function forkThumbnailClicked() {
    if ($(this).hasClass('disabled')) return false;

    $('.fork-namespaces').hide();
    return $('.save-project-loader').show();
  });
};
