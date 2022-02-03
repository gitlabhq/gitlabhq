import imageDiffHelper from './helpers/index';
import ImageDiff from './image_diff';
import { viewTypes, isValidViewType } from './view_types';

export default class ReplacedImageDiff extends ImageDiff {
  init(defaultViewType = viewTypes.TWO_UP) {
    this.imageFrameEls = {
      [viewTypes.TWO_UP]: this.el.querySelector('.two-up .js-image-frame'),
      [viewTypes.SWIPE]: this.el.querySelector('.swipe .js-image-frame'),
      [viewTypes.ONION_SKIN]: this.el.querySelector('.onion-skin .js-image-frame'),
    };

    const viewModesEl = this.el.querySelector('.view-modes-menu');
    this.viewModesEls = {
      [viewTypes.TWO_UP]: viewModesEl.querySelector('.two-up'),
      [viewTypes.SWIPE]: viewModesEl.querySelector('.swipe'),
      [viewTypes.ONION_SKIN]: viewModesEl.querySelector('.onion-skin'),
    };

    this.currentView = defaultViewType;
    this.generateImageEls();
    this.bindEvents();
  }

  generateImageEls() {
    this.imageEls = {};

    const viewTypeNames = Object.getOwnPropertyNames(viewTypes);
    viewTypeNames.forEach((viewType) => {
      this.imageEls[viewType] = this.imageFrameEls[viewType].querySelector('img');
    });
  }

  bindEvents() {
    super.bindEvents();

    this.changeToViewTwoUp = this.changeView.bind(this, viewTypes.TWO_UP);
    this.changeToViewSwipe = this.changeView.bind(this, viewTypes.SWIPE);
    this.changeToViewOnionSkin = this.changeView.bind(this, viewTypes.ONION_SKIN);

    this.viewModesEls[viewTypes.TWO_UP].addEventListener('click', this.changeToViewTwoUp);
    this.viewModesEls[viewTypes.SWIPE].addEventListener('click', this.changeToViewSwipe);
    this.viewModesEls[viewTypes.ONION_SKIN].addEventListener('click', this.changeToViewOnionSkin);
  }

  get imageEl() {
    return this.imageEls[this.currentView];
  }

  get imageFrameEl() {
    return this.imageFrameEls[this.currentView];
  }

  changeView(newView) {
    if (!isValidViewType(newView)) {
      return;
    }

    const indicator = imageDiffHelper.removeCommentIndicator(this.imageFrameEl);

    this.currentView = newView;

    // Clear existing badges on new view
    const existingBadges = this.imageFrameEl.querySelectorAll('.design-note-pin');
    [...existingBadges].map((badge) => badge.remove());

    // Remove existing references to old view image badges
    this.imageBadges = [];

    // Image_file.js has a fade animation of 200ms for loading the view
    // Need to wait an additional 250ms for the images to be displayed
    // on window in order to re-normalize their dimensions
    setTimeout(this.renderNewView.bind(this, indicator), 250);
  }

  renderNewView(indicator) {
    // Generate badge coordinates on new view
    this.renderBadges();

    // Re-render indicator in new view
    if (indicator.removed) {
      const normalizedIndicator = imageDiffHelper.resizeCoordinatesToImageElement(this.imageEl, {
        x: indicator.x,
        y: indicator.y,
        width: indicator.image.width,
        height: indicator.image.height,
      });
      imageDiffHelper.showCommentIndicator(this.imageFrameEl, normalizedIndicator);
    }
  }
}
