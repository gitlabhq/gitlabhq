import $ from 'jquery';

export default () => {
  $('.js-fork-thumbnail').on('click', function forkThumbnailClicked() {
    if ($(this).hasClass('disabled')) return false;

    return $('.js-fork-content').toggle();
  });
};
