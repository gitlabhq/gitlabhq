import * as imageDiffHelper from './image_diff_helper';
import ImageDiff from './image_diff';

const viewTypes = {
  TWO_UP: 'TWO_UP',
  SWIPE: 'SWIPE',
  ONION_SKIN: 'ONION_SKIN',
};

const defaultViewType = viewTypes.TWO_UP;

// TODO: Determine whether we can refactor imageDiff and this into one file
export default class ReplacedImageDiff extends ImageDiff {
  constructor(el, canCreateNote) {
    super(el, canCreateNote);

    this.imageFrameEls = {
      [viewTypes.TWO_UP]: el.querySelectorAll('.two-up .frame')[1],
      [viewTypes.SWIPE]: el.querySelector('.swipe .swipe-wrap .frame'),
      [viewTypes.ONION_SKIN]: el.querySelectorAll('.onion-skin .frame')[1],
    };

    // TODO: Refactor into a method to auto generate each of them
    this.imageEls = {
      [viewTypes.TWO_UP]: this.imageFrameEls[viewTypes.TWO_UP].querySelector('img'),
      [viewTypes.SWIPE]: this.imageFrameEls[viewTypes.SWIPE].querySelector('img'),
      [viewTypes.ONION_SKIN]: this.imageFrameEls[viewTypes.ONION_SKIN].querySelector('img'),
    };

    this.currentView = defaultViewType;
  }

  bindEvents(canCreateNote) {
    this.clickWrapper = this.click.bind(this);
    this.changeToViewTwoUp = this.changeView.bind(this, viewTypes.TWO_UP);
    this.changeToViewSwipe = this.changeView.bind(this, viewTypes.SWIPE);
    this.changeToViewOnionSkin = this.changeView.bind(this, viewTypes.ONION_SKIN);
    this.renderBadgesWrapper = this.renderBadges.bind(this);

    const viewModesEl = this.el.querySelector('.view-modes-menu');
    viewModesEl.querySelector('.two-up').addEventListener('click', this.changeToViewTwoUp);
    viewModesEl.querySelector('.swipe').addEventListener('click', this.changeToViewSwipe);
    viewModesEl.querySelector('.onion-skin').addEventListener('click', this.changeToViewOnionSkin);

    // Render image badges after the image diff is loaded
    this.getImageEl(this.currentView).addEventListener('load', this.renderBadgesWrapper);

    if (canCreateNote) {
      this.el.addEventListener('click.imageDiff', this.clickWrapper);
    } else {
      this.disableCursor();
    }
  }

  changeView(newView) {
    const indicator = imageDiffHelper.removeCommentIndicator(this.getImageFrameEl());

    // TODO: add validation for newView to match viewTypes
    this.currentView = newView;

    // Clear existing badges on new view
    const existingBadges = this.getImageFrameEl().querySelectorAll('.badge');
    [].map.call(existingBadges, badge => badge.remove());

    // Image_file.js has a fade animation for loading the view
    // Need to wait for the images to load in order to re-normalize
    // their dimensions
    setTimeout(() => {
      // Re-normalize badge coordinates based on dimensions of image view
      this.imageBadges.forEach(badge => badge.generateBrowserMeta(this.getImageEl()));

      this.renderBadgesWrapper();

      // Re-render indicator in new view
      if (indicator.removed) {
        // Re-normalize indicator x,y
        const normalizedIndicator = imageDiffHelper.generateBrowserMeta(this.getImageEl(), {
          x: indicator.x,
          y: indicator.y,
          width: indicator.image.width,
          height: indicator.image.height,
        });
        imageDiffHelper.showCommentIndicator(this.getImageFrameEl(), normalizedIndicator);
      }
    }, 300);
  }

  click(event) {
    const customEvent = event.detail;
    const selection = imageDiffHelper.getTargetSelection(customEvent);
    const el = customEvent.currentTarget;

    imageDiffHelper.setPositionDataAttribute(el, selection.actual);
    imageDiffHelper.showCommentIndicator(this.getImageFrameEl(), selection.browser);
  }

  getImageEl() {
    return this.imageEls[this.currentView];
  }

  getImageFrameEl() {
    return this.imageFrameEls[this.currentView];
  }

  renderBadges() {
    const discussionsEls = this.el.querySelectorAll('.note-container .discussion-notes .notes');

    [].forEach.call(discussionsEls, (discussionEl, index) => {
      const imageBadge = imageDiffHelper
        .generateBadgeFromDiscussionDOM(this.getImageFrameEl(), discussionEl);

      this.imageBadges.push(imageBadge);

      imageDiffHelper.addCommentBadge(this.getImageFrameEl(), {
        coordinate: imageBadge.browser,
        badgeText: index + 1,
        noteId: imageBadge.noteId,
      });
    });
  }
}
