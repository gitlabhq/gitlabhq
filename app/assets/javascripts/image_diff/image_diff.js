import * as imageDiffHelper from './image_diff_helper';

export default class ImageDiff {
  constructor(el) {
    this.el = el;
    this.imageFrame = el.querySelector('.diff-viewer .image .frame');
    this.image = this.imageFrame.querySelector('img');
    this.badges = [];
  }

  bindEvents(canCreateNote) {
    this.clickWrapper = this.click.bind(this);
    this.blurWrapper = this.blur.bind(this);
    this.renderBadgesWrapper = this.renderBadges.bind(this);
    this.addAvatarBadgeWrapper = this.addAvatarBadge.bind(this);
    this.addBadgeWrapper = this.addBadge.bind(this);
    this.removeBadgeWrapper = this.removeBadge.bind(this);

    // Render badges after the image diff is loaded
    this.image.addEventListener('load', this.renderBadgesWrapper);

    if (canCreateNote) {
      this.el.addEventListener('click.imageDiff', this.clickWrapper);
      this.el.addEventListener('blur.imageDiff', this.blurWrapper);
      this.el.addEventListener('addBadge.imageDiff', this.addBadgeWrapper);
      this.el.addEventListener('addAvatarBadge.imageDiff', this.addAvatarBadgeWrapper);
      this.el.addEventListener('removeBadge.imageDiff', this.removeBadgeWrapper);
    } else {
      this.disableCursor();
    }
  }

  unbindEvents() {
    this.el.removeEventListener('click.imageDiff', this.clickWrapper);
    this.el.removeEventListener('blur.imageDiff', this.blurWrapper);
    this.el.removeEventListener('addBadge.imageDiff', this.addBadgeWrapper);
    this.el.removeEventListener('addAvatarBadge.imageDiff', this.addAvatarBadgeWrapper);
    this.el.removeEventListener('removeBadge.imageDiff', this.removeBadgeWrapper);

    this.image.removeEventListener('load', this.renderBadgesWrapper);
  }

  disableCursor() {
    this.imageFrame.style.cursor = 'auto';
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
        discussionId: discussion.dataset.discussionId,
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

    this.addAvatarBadge({
      detail: {
        noteId,
        badgeNumber: badgeText,
      },
    });

    this.badges.push(badge);
  }

  addAvatarBadge(event) {
    const { noteId, badgeNumber } = event.detail;

    // Add badge to new comment
    const avatarBadge = this.el.querySelector(`#${noteId} .badge`);
    avatarBadge.innerText = badgeNumber;
    avatarBadge.classList.remove('hidden');
  }

  removeBadge(event) {
    const { badgeNumber } = event.detail;

    const imageBadges = this.imageFrame.querySelectorAll('.badge');

    if (this.badges.length !== badgeNumber) {
      // Cascade badges count numbers for (avatar badges + image badges)
      this.badges.forEach((badge, index) => {
        if (index > badgeNumber - 1) {
          const updatedBadgeNumber = index;
          imageBadges[index].innerText = updatedBadgeNumber;

          const { discussionId } = badge;
          const discussionEl = this.el.querySelector(`.notes[data-discussion-id="${discussionId}"]`);
          const discussionBadgeEl = discussionEl.querySelector('.badge');
          discussionBadgeEl.innerText = updatedBadgeNumber;

          const avatarBadges = discussionEl.querySelectorAll('.image-diff-avatar-link .badge');

          [].map.call(avatarBadges, avatarBadge =>
            Object.assign(avatarBadge, {
              innerText: updatedBadgeNumber,
            }),
          );
        }
      });
    }

    this.badges.splice(badgeNumber - 1, 1);
    const selectedImageBadge = imageBadges[badgeNumber - 1];
    selectedImageBadge.remove();
  }
}
