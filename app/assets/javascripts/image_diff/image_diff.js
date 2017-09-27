import * as imageDiffHelper from './image_diff_helper';

export default class ImageDiff {
  constructor(el) {
    this.el = el;
    this.imageFrame = el.querySelector('.diff-viewer .image .frame');
    this.image = this.imageFrame.querySelector('img');
    this.badges = [];
  }

  bindEvents() {
    this.clickWrapper = this.click.bind(this);
    this.blurWrapper = this.blur.bind(this);
    this.renderBadgesWrapper = this.renderBadges.bind(this);
    this.addBadgeWrapper = this.addBadge.bind(this);

    this.el.addEventListener('click.imageDiff', this.clickWrapper);
    this.el.addEventListener('blur.imageDiff', this.blurWrapper);
    this.el.addEventListener('addBadge.imageDiff', this.addBadgeWrapper);

    // Render badges after the image diff is loaded
    this.image.addEventListener('load', this.renderBadgesWrapper);
  }

  unbindEvents() {
    this.el.removeEventListener('click.imageDiff', this.clickWrapper);
    this.el.removeEventListener('blur.imageDiff', this.blurWrapper);
    this.el.removeEventListener('addBadge.imageDiff', this.addBadgeWrapper);

    this.image.removeEventListener('load', this.renderBadgesWrapper);
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
    imageDiffHelper.setPositionDataAttribute(el, selection.actual);
  }

  // TODO: Rename to something better?
  blur() {
    const commentIndicator = this.imageFrame.querySelector('.comment-indicator');

    if (commentIndicator) {
      commentIndicator.remove();
    }
  }

  renderBadges() {
    // Process existing badges from html
    const browserImage = this.imageFrame.querySelector('img');
    const discussions = this.el.querySelectorAll('.note-container .discussion-notes .notes');

    [].forEach.call(discussions, (discussion, index) => {
      const position = JSON.parse(discussion.dataset.position);
      const firstNote = discussion.querySelector('.note');

      const actual = {
        x: position.x_axis,
        y: position.y_axis,
        width: position.width,
        height: position.height,
      };

      const badge = {
        actual,
        browser: imageDiffHelper.createBadgeBrowserFromActual(browserImage, actual),
        noteId: firstNote.id,
      };

      imageDiffHelper.addCommentBadge(this.imageFrame, {
        coordinate: badge.browser,
        badgeText: index + 1,
        noteId: badge.noteId,
      });

      this.badges.push(badge);
    });
  }

  addBadge(event) {
    const { x, y, width, height, noteId } = event.detail;
    const actual = {
      x,
      y,
      width,
      height,
    };

    const browserImage = this.imageFrame.querySelector('img');
    const badgeText = this.badges.length + 1;
    const badge = {
      actual,
      browser: imageDiffHelper.createBadgeBrowserFromActual(browserImage, actual),
      noteId,
    };

    imageDiffHelper.addCommentBadge(this.imageFrame, {
      coordinate: badge.browser,
      badgeText,
      noteId,
    });

    // Add badge to new comment
    const avatarBadge = this.el.querySelector(`#${noteId} .badge`);
    avatarBadge.innerText = badgeText;
    avatarBadge.classList.remove('hidden');

    this.badges.push(badge);
  }
}
