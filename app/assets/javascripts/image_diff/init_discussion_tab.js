import imageDiffHelper from './helpers/index';

export default () => {
  // Always pass can-create-note as false because a user
  // cannot place new badge markers on discussion tab
  const canCreateNote = false;
  const renderCommentBadge = true;

  const diffFileEls = document.querySelectorAll('.timeline-content .diff-file.js-image-file');
  [].forEach.call(diffFileEls, diffFileEl =>
    imageDiffHelper.initImageDiff(diffFileEl, canCreateNote, renderCommentBadge));

  $('.timeline-content .diff-file').on('click', '.js-image-badge', imageDiffHelper.imageBadgeOnClick);
};
