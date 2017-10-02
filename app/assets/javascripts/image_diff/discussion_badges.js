// TODO Rename this file to explain what it does better
import imageDiffHelper from './helpers/index';

export function init() {
  const diffFileEls = document.querySelectorAll('.timeline-content .diff-file.js-image-file');
  [].forEach.call(diffFileEls, (diffFileEl) => {
    // ImageFile needs to be invoked before initImageDiff so that badges
    // can mount to the correct location
    new gl.ImageFile(diffFileEl); // eslint-disable-line no-new

    // Always pass can-create-note as false because user cannot place new badge markers
    // on discussion tab
    const canCreateNote = false;
    const renderCommentBadge = true;
    imageDiffHelper.initImageDiff(diffFileEl, canCreateNote, renderCommentBadge);
  });

  // TODO: Related to image diff.js line 50
  $('.timeline-content .diff-file').on('click', '.js-image-badge', imageDiffHelper.imageBadgeOnClick);
}
