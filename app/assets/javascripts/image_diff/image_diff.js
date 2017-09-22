import * as imageDiffHelper from './image_diff_helper';

export function setCommentSelectionIndicator(event) {
  const container = event.target.parentElement;
  const commentSelection = container.querySelector('.comment-selection');
  const selection = imageDiffHelper.getTargetSelection(event);

  if (commentSelection) {
    commentSelection.style.left = `${selection.browser.x}px`;
    commentSelection.style.top = `${selection.browser.y}px`;
  } else {
    const button = imageDiffHelper
      .addCommentSelectionIndicator(container, selection.browser);

    button.addEventListener('click', imageDiffHelper.commentSelectionIndicatorOnClick);
  }
}

export function setupCoordinatesData(event) {
  const el = event.currentTarget;
  const selection = imageDiffHelper.getTargetSelection(event);

  imageDiffHelper.setLineCodeCoordinates(el, selection.actual);
  imageDiffHelper.setPositionDataAttribute(el, selection.actual);
}
