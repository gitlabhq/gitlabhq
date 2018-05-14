import $ from 'jquery';
import imageDiffHelper from './helpers/index';
import ImageBadge from './image_badge';
import { isImageLoaded } from '../lib/utils/image_utility';

export default class ImageDiff {
  constructor(el, options) {
    this.el = el;
    this.canCreateNote = !!(options && options.canCreateNote);
    this.renderCommentBadge = !!(options && options.renderCommentBadge);
    this.$noteContainer = $('.note-container', this.el);
    this.imageBadges = [];
  }

  init() {
    this.imageFrameEl = this.el.querySelector('.diff-file .js-image-frame');
    this.imageEl = this.imageFrameEl.querySelector('img');

    this.bindEvents();
  }

  bindEvents() {
    this.imageClickedWrapper = this.imageClicked.bind(this);
    this.imageBlurredWrapper = imageDiffHelper.removeCommentIndicator.bind(null, this.imageFrameEl);
    this.addBadgeWrapper = this.addBadge.bind(this);
    this.removeBadgeWrapper = this.removeBadge.bind(this);
    this.renderBadgesWrapper = this.renderBadges.bind(this);

    // Render badges
    if (isImageLoaded(this.imageEl)) {
      this.renderBadges();
    } else {
      this.imageEl.addEventListener('load', this.renderBadgesWrapper);
    }

    // jquery makes the event delegation here much simpler
    this.$noteContainer.on('click', '.js-diff-notes-toggle', imageDiffHelper.toggleCollapsed);
    $(this.el).on('click', '.comment-indicator', imageDiffHelper.commentIndicatorOnClick);

    if (this.canCreateNote) {
      this.el.addEventListener('click.imageDiff', this.imageClickedWrapper);
      this.el.addEventListener('blur.imageDiff', this.imageBlurredWrapper);
      this.el.addEventListener('addBadge.imageDiff', this.addBadgeWrapper);
      this.el.addEventListener('removeBadge.imageDiff', this.removeBadgeWrapper);
    }
  }

  imageClicked(event) {
    const customEvent = event.detail;
    const selection = imageDiffHelper.getTargetSelection(customEvent);
    const el = customEvent.currentTarget;

    imageDiffHelper.setPositionDataAttribute(el, selection.actual);
    imageDiffHelper.showCommentIndicator(this.imageFrameEl, selection.browser);
  }

  renderBadges() {
    const discussionsEls = this.el.querySelectorAll('.note-container .discussion-notes .notes');
    [...discussionsEls].forEach(this.renderBadge.bind(this));
  }

  renderBadge(discussionEl, index) {
    const imageBadge = imageDiffHelper
      .generateBadgeFromDiscussionDOM(this.imageFrameEl, discussionEl);

    this.imageBadges.push(imageBadge);

    const options = {
      coordinate: imageBadge.browser,
      noteId: imageBadge.noteId,
    };

    if (this.renderCommentBadge) {
      imageDiffHelper.addImageCommentBadge(this.imageFrameEl, options);
    } else {
      const numberBadgeOptions = Object.assign({}, options, {
        badgeText: index + 1,
      });

      imageDiffHelper.addImageBadge(this.imageFrameEl, numberBadgeOptions);
    }
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

    imageDiffHelper.addImageBadge(this.imageFrameEl, {
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

    const discussionEl = this.el.querySelector(`#discussion_${discussionId}`);
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
          const discussionEl = this.el.querySelector(`#discussion_${discussionId}`);

          imageBadgeEls[index].innerText = updatedBadgeNumber;

          imageDiffHelper.updateDiscussionBadgeNumber(discussionEl, updatedBadgeNumber);
          imageDiffHelper.updateDiscussionAvatarBadgeNumber(discussionEl, updatedBadgeNumber);
        }
      });
    }

    this.imageBadges.splice(indexToRemove, 1);

    const imageBadgeEl = imageBadgeEls[indexToRemove];
    imageBadgeEl.remove();
  }
}
