import * as imageDiffHelper from './image_diff_helper';

export function showCommentIndicator(event) {
  const container = event.target.parentElement;
  const commentIndicator = container.querySelector('.comment-indicator');
  const selection = imageDiffHelper.getTargetSelection(event);

  if (commentIndicator) {
    commentIndicator.style.left = `${selection.browser.x}px`;
    commentIndicator.style.top = `${selection.browser.y}px`;
  } else {
    const button = imageDiffHelper
      .addCommentIndicator(container, selection.browser);

    button.addEventListener('click', imageDiffHelper.commentIndicatorOnClick);
  }
}

export function hideCommentIndicator(event) {
  const container = event.target.closest('.diff-viewer');
  const commentIndicator = container.querySelector('.comment-indicator');

  if (commentIndicator) {
    commentIndicator.remove();
  }
}

export function setupCoordinatesData(event) {
  const el = event.currentTarget;
  const selection = imageDiffHelper.getTargetSelection(event);

  imageDiffHelper.setLineCodeCoordinates(el, selection.actual);
  imageDiffHelper.setPositionDataAttribute(el, selection.actual);
}
