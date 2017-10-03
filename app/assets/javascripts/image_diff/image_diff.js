import imageDiffHelper from './helpers/index';
import ImageBadge from './image_badge';
import { isImageLoaded } from '../lib/utils/image_utility';

export default class ImageDiff {
  constructor(el, {
    canCreateNote = false,
    renderCommentBadge = false,
  }) {
    this.el = el;
    this.canCreateNote = canCreateNote;
    this.renderCommentBadge = renderCommentBadge;
    this.$noteContainer = $('.note-container', this.el);
    this.imageBadges = [];
  }

  init() {
    this.imageFrameEl = this.el.querySelector('.diff-file .image .frame');
    this.imageEl = this.imageFrameEl.querySelector('img');

    this.bindEvents();
  }

  getImageEl() {
    return this.imageEl;
  }

  getImageFrameEl() {
    return this.imageFrameEl;
  }

  bindEvents() {
    this.clickWrapper = this.click.bind(this);
    this.blurWrapper = this.blur.bind(this);
    this.addBadgeWrapper = this.addBadge.bind(this);
    this.addAvatarBadgeWrapper = imageDiffHelper.addAvatarBadge.bind(null, this.el);
    this.removeBadgeWrapper = this.removeBadge.bind(this);
    this.renderBadgesWrapper = this.renderBadges.bind(this);

    // Render badges
    if (isImageLoaded(this.getImageEl())) {
      this.renderBadges();
    } else {
      this.getImageEl().addEventListener('load', this.renderBadgesWrapper);
    }

    // jquery makes the event delegation here much simpler
    this.$noteContainer.on('click', '.js-diff-notes-toggle', imageDiffHelper.toggleCollapsed);
    $(this.el).on('click', '.comment-indicator', imageDiffHelper.commentIndicatorOnClick);

    if (this.canCreateNote) {
      this.el.addEventListener('click.imageDiff', this.clickWrapper);
      this.el.addEventListener('blur.imageDiff', this.blurWrapper);
      this.el.addEventListener('addBadge.imageDiff', this.addBadgeWrapper);
      this.el.addEventListener('addAvatarBadge.imageDiff', this.addAvatarBadgeWrapper);
      this.el.addEventListener('removeBadge.imageDiff', this.removeBadgeWrapper);
    }
  }

  unbindEvents() {
    this.imageEl.removeEventListener('load', this.renderBadgesWrapper);
    this.$noteContainer.off('click', '.js-diff-notes-toggle', imageDiffHelper.toggleCollapsed);
    $(this.el).off('click', '.comment-indicator', imageDiffHelper.commentIndicatorOnClick);

    if (this.canCreateNote) {
      this.el.removeEventListener('click.imageDiff', this.clickWrapper);
      this.el.removeEventListener('blur.imageDiff', this.blurWrapper);
      this.el.removeEventListener('addBadge.imageDiff', this.addBadgeWrapper);
      this.el.removeEventListener('addAvatarBadge.imageDiff', this.addAvatarBadgeWrapper);
      this.el.removeEventListener('removeBadge.imageDiff', this.removeBadgeWrapper);
    }
  }

  click(event) {
    const customEvent = event.detail;
    const selection = imageDiffHelper.getTargetSelection(customEvent);
    const el = customEvent.currentTarget;

    imageDiffHelper.setPositionDataAttribute(el, selection.actual);
    imageDiffHelper.showCommentIndicator(this.getImageFrameEl(), selection.browser);
  }

  blur() {
    return imageDiffHelper.removeCommentIndicator(this.getImageFrameEl());
  }

  renderBadges() {
    const discussionsEls = this.el.querySelectorAll('.note-container .discussion-notes .notes');

    [].forEach.call(discussionsEls, (discussionEl, index) => {
      const imageBadge = imageDiffHelper
        .generateBadgeFromDiscussionDOM(this.getImageFrameEl(), discussionEl);

      this.imageBadges.push(imageBadge);

      const options = {
        coordinate: imageBadge.browser,
        noteId: imageBadge.noteId,
      };

      if (this.renderCommentBadge) {
        imageDiffHelper.addImageCommentBadge(this.getImageFrameEl(), options);
      } else {
        const numberBadgeOptions = Object.assign(options, {
          badgeText: index + 1,
        });

        imageDiffHelper.addImageBadge(this.getImageFrameEl(), numberBadgeOptions);
      }
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
      imageEl: this.getImageFrameEl().querySelector('img'),
      noteId,
      discussionId,
    });

    this.imageBadges.push(imageBadge);

    imageDiffHelper.addImageBadge(this.getImageFrameEl(), {
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
    const imageBadgeEls = this.getImageFrameEl().querySelectorAll('.badge');

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
