import * as imageDiffHelper from './image_diff_helper';

export default class ImageDiff {
  constructor(el) {
    this.el = el;
    this.imageFrame = el.querySelector('.diff-viewer .image .frame');
  }

  bindEvents() {
    this.clickWrapper = this.click.bind(this);
    this.blurWrapper = this.blur.bind(this);

    this.el.addEventListener('click.imageDiff', this.clickWrapper);
    this.el.addEventListener('blur.imageDiff', this.blurWrapper);
    this.el.addEventListener('renderBadges.imageDiff', ImageDiff.renderBadges);
    this.el.addEventListener('updateBadges.imageDiff', ImageDiff.updateBadges);
  }

  unbindEvents() {
    this.el.removeEventListener('click.imageDiff', this.clickWrapper);
    this.el.removeEventListener('blur.imageDiff', this.blurWrapper);
    this.el.removeEventListener('renderBadges.imageDiff', ImageDiff.renderBadges);
    this.el.removeEventListener('updateBadges.imageDiff', ImageDiff.updateBadges);
  }

  click(event) {
    const customEvent = event.detail;
    const selection = imageDiffHelper.getTargetSelection(customEvent);

    // showCommentIndicator
    const commentIndicator = this.imageFrame.querySelector('.comment-indicator');

    if (commentIndicator) {
      commentIndicator.style.left = `${selection.browser.x}px`;
      commentIndicator.style.top = `${selection.browser.y}px`;
    } else {
      const button = imageDiffHelper
        .addCommentIndicator(this.imageFrame, selection.browser);

      button.addEventListener('click', imageDiffHelper.commentIndicatorOnClick);
    }

    // setupCoordinatesData
    const el = customEvent.currentTarget;
    imageDiffHelper.setLineCodeCoordinates(el, selection.actual);
    imageDiffHelper.setPositionDataAttribute(el, selection.actual);
  }

  // TODO: Rename to something better?
  blur() {
    const commentIndicator = this.imageFrame.querySelector('.comment-indicator');

    if (commentIndicator) {
      commentIndicator.remove();
    }
  }

  static renderBadges() {

  }

  static updateBadges() {

  }
}
