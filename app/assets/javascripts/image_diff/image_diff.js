import * as imageDiffHelper from './image_diff_helper';
import ImageBadge from './image_badge';

export default class ImageDiff {
  constructor(el, canCreateNote = false) {
    this.el = el;
    this.canCreateNote = canCreateNote;
    this.imageFrameEl = el.querySelector('.diff-viewer .image .frame');
    this.imageEl = this.imageFrameEl.querySelector('img');
    this.noteContainer = this.el.querySelector('.note-container');
    this.imageBadges = [];
  }

  bindEvents() {
    this.clickWrapper = this.click.bind(this);
    this.blurWrapper = imageDiffHelper.removeCommentIndicator.bind(null, this.imageFrameEl);
    this.renderBadgesWrapper = this.renderBadges.bind(this);
    this.addAvatarBadgeWrapper = imageDiffHelper.addAvatarBadge.bind(null, this.el);
    this.addBadgeWrapper = this.addBadge.bind(this);
    this.toggleCollapsedWrapper = this.toggleCollapsed.bind(this);
    this.removeBadgeWrapper = this.removeBadge.bind(this);

    // Render badges after the image diff is loaded
    this.imageEl.addEventListener('load', this.renderBadgesWrapper);

    // jquery makes the event delegation here much simpler
    $(this.noteContainer).on('click', '.js-diff-notes-toggle', this.toggleCollapsedWrapper);

    if (this.canCreateNote) {
      this.el.addEventListener('click.imageDiff', this.clickWrapper);
      this.el.addEventListener('blur.imageDiff', this.blurWrapper);
      this.el.addEventListener('addBadge.imageDiff', this.addBadgeWrapper);
      this.el.addEventListener('addAvatarBadge.imageDiff', this.addAvatarBadgeWrapper);
      this.el.addEventListener('removeBadge.imageDiff', this.removeBadgeWrapper);
    }
  }

  unbindEvents() {
    if (this.canCreateNote) {
      this.el.removeEventListener('click.imageDiff', this.clickWrapper);
      this.el.removeEventListener('blur.imageDiff', this.blurWrapper);
      this.el.removeEventListener('addBadge.imageDiff', this.addBadgeWrapper);
      this.el.removeEventListener('addAvatarBadge.imageDiff', this.addAvatarBadgeWrapper);
      this.el.removeEventListener('removeBadge.imageDiff', this.removeBadgeWrapper);
    }

    this.noteContainer.removeEventListener('click', this.toggleCollapsedWrapper);
    this.imageEl.removeEventListener('load', this.renderBadgesWrapper);
  }

  toggleCollapsed(e) {
    const $toggleBtn = $(e.currentTarget);

    $toggleBtn.closest('.discussion-notes').toggleClass('collapsed');
  }

  click(event) {
    const customEvent = event.detail;
    const selection = imageDiffHelper.getTargetSelection(customEvent);
    const el = customEvent.currentTarget;

    imageDiffHelper.setPositionDataAttribute(el, selection.actual);
    imageDiffHelper.showCommentIndicator(this.imageFrameEl, selection.browser);
  }

  renderBadges() {
    const discussionsEls = this.el.querySelectorAll('.note-container .discussion-notes .notes');

    [].forEach.call(discussionsEls, (discussionEl, index) => {
      const imageBadge = imageDiffHelper
        .generateBadgeFromDiscussionDOM(this.imageFrameEl, discussionEl);

      this.imageBadges.push(imageBadge);

      imageDiffHelper.addCommentBadge(this.imageFrameEl, {
        coordinate: imageBadge.browser,
        badgeText: index + 1,
        noteId: imageBadge.noteId,
      });
    });
  }

  addBadge(event) {
    const { x, y, width, height, noteId, discussionId } = event.detail;
    const badgeText = this.imageBadges.length + 1;
    const imageBadge = new ImageBadge({
      actual: {
        x,
        y,
        width,
        height,
      },
      imageEl: this.imageFrameEl.querySelector('img'),
      noteId,
      discussionId,
    });

    this.imageBadges.push(imageBadge);

    imageDiffHelper.addCommentBadge(this.imageFrameEl, {
      coordinate: imageBadge.browser,
      badgeText,
      noteId,
    });

    imageDiffHelper.addAvatarBadge(this.el, {
      detail: {
        noteId,
        badgeNumber: badgeText,
      },
    });

    const discussionEl = this.el.querySelector(`.notes[data-discussion-id="${discussionId}"]`);
    imageDiffHelper.updateDiscussionBadgeNumber(discussionEl, badgeText);
  }

  removeBadge(event) {
    const { badgeNumber } = event.detail;
    const indexToRemove = badgeNumber - 1;
    const imageBadgeEls = this.imageFrameEl.querySelectorAll('.badge');

    if (this.imageBadges.length !== badgeNumber) {
      // Cascade badges count numbers for (avatar badges + image badges)
      this.imageBadges.forEach((badge, index) => {
        if (index > indexToRemove) {
          const { discussionId } = badge;
          const updatedBadgeNumber = index;
          const discussionEl = this.el.querySelector(`.notes[data-discussion-id="${discussionId}"]`);

          imageBadgeEls[index].innerText = updatedBadgeNumber;

          imageDiffHelper.updateDiscussionBadgeNumber(discussionEl, updatedBadgeNumber);
          imageDiffHelper.updateAvatarBadgeNumber(discussionEl, updatedBadgeNumber);
        }
      });
    }

    this.imageBadges.splice(indexToRemove, 1);

    const imageBadgeEl = imageBadgeEls[indexToRemove];
    imageBadgeEl.remove();
  }
}
