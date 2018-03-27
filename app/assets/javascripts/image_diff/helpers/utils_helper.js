import ImageBadge from '../image_badge';
import ImageDiff from '../image_diff';
import ReplacedImageDiff from '../replaced_image_diff';
import ImageFile from '../../commit/image_file';

export function resizeCoordinatesToImageElement(imageEl, meta) {
  const { x, y, width, height } = meta;

  const imageWidth = imageEl.width;
  const imageHeight = imageEl.height;

  const widthRatio = imageWidth / width;
  const heightRatio = imageHeight / height;

  return {
    x: Math.round(x * widthRatio),
    y: Math.round(y * heightRatio),
    width: imageWidth,
    height: imageHeight,
  };
}

export function generateBadgeFromDiscussionDOM(imageFrameEl, discussionEl) {
  const position = JSON.parse(discussionEl.dataset.position);
  const firstNoteEl = discussionEl.querySelector('.note');
  const badge = new ImageBadge({
    actual: position,
    imageEl: imageFrameEl.querySelector('img'),
    noteId: firstNoteEl.id,
    discussionId: discussionEl.dataset.discussionId,
  });

  return badge;
}

export function getTargetSelection(event) {
  const containerEl = event.currentTarget;
  const imageEl = containerEl.querySelector('img');

  const x = event.offsetX;
  const y = event.offsetY;

  const width = imageEl.width;
  const height = imageEl.height;

  const actualWidth = imageEl.naturalWidth;
  const actualHeight = imageEl.naturalHeight;

  const widthRatio = actualWidth / width;
  const heightRatio = actualHeight / height;

  // Browser will include the frame as a clickable target,
  // which would result in potential 1px out of bounds value
  // This bound the coordinates to inside the frame
  const normalizedX = Math.max(0, x) && Math.min(x, width);
  const normalizedY = Math.max(0, y) && Math.min(y, height);

  return {
    browser: {
      x: normalizedX,
      y: normalizedY,
      width,
      height,
    },
    actual: {
      // Round x, y so that we don't need to deal with decimals
      x: Math.round(normalizedX * widthRatio),
      y: Math.round(normalizedY * heightRatio),
      width: actualWidth,
      height: actualHeight,
    },
  };
}

export function initImageDiff(fileEl, canCreateNote, renderCommentBadge) {
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
