import ImageFile from '~/commit/image_file';
import ImageDiff from '../image_diff';
import ReplacedImageDiff from '../replaced_image_diff';

function initImageDiff(fileEl, canCreateNote, renderCommentBadge) {
  const options = {
    canCreateNote,
    renderCommentBadge,
  };
  let diff;

  // ImageFile needs to be invoked before initImageDiff so that badges
  // can mount to the correct location
  new ImageFile(fileEl); // eslint-disable-line no-new

  if (fileEl.querySelector('.diff-file .js-single-image')) {
    diff = new ImageDiff(fileEl, options);
    diff.init();
  } else if (fileEl.querySelector('.diff-file .js-replaced-image')) {
    diff = new ReplacedImageDiff(fileEl, options);
    diff.init();
  }

  return diff;
}

export default { initImageDiff };
