import imageDiffHelper from './helpers/index';

export function create(imageEl) {
  const imageFrameEl = imageEl.closest('.frame');
  const { x_axis, y_axis, width, height } = JSON.parse(imageFrameEl.dataset.position);

  const meta = imageDiffHelper.resizeCoordinatesToImageElement(imageEl, {
    x: x_axis,
    y: y_axis,
    width,
    height,
  });

  const diffFile = imageFrameEl.closest('.diff-file');
  const firstNote = diffFile.querySelector('.discussion-notes .note');

  imageDiffHelper.addImageCommentBadge(imageFrameEl, {
    coordinate: {
      x: meta.x,
      y: meta.y,
    },
    noteId: firstNote.id,
  });
}

export function init() {
  const imageEls = document.querySelectorAll('.timeline-content .diff-file .image .frame img');
  [].forEach.call(imageEls, imageEl => imageEl.addEventListener('load', create.bind(null, imageEl)));

  $('.timeline-content .diff-file').on('click', '.js-image-badge', imageDiffHelper.imageBadgeOnClick);
}
