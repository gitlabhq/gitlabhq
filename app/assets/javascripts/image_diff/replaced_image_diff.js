import * as imageDiffHelper from './image_diff_helper';
import { viewTypes, isValidViewType } from './view_types';
import ImageDiff from './image_diff';

export default class ReplacedImageDiff extends ImageDiff {
  init(defaultViewType = viewTypes.TWO_UP) {
    this.imageFrameEls = {
      [viewTypes.TWO_UP]: this.el.querySelectorAll('.two-up .frame')[1],
      [viewTypes.SWIPE]: this.el.querySelector('.swipe .swipe-wrap .frame'),
      [viewTypes.ONION_SKIN]: this.el.querySelectorAll('.onion-skin .frame')[1],
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

    const viewModesEl = this.el.querySelector('.view-modes-menu');
    viewModesEl.querySelector('.two-up').addEventListener('click', this.changeToViewTwoUp);
    viewModesEl.querySelector('.swipe').addEventListener('click', this.changeToViewSwipe);
    viewModesEl.querySelector('.onion-skin').addEventListener('click', this.changeToViewOnionSkin);
  }

  getImageEl() {
    return this.imageEls[this.currentView];
  }

  getImageFrameEl() {
    return this.imageFrameEls[this.currentView];
  }

  changeView(newView) {
    if (!isValidViewType(newView)) {
      return;
    }

    const indicator = imageDiffHelper.removeCommentIndicator(this.getImageFrameEl());

    this.currentView = newView;

    // Clear existing badges on new view
    const existingBadges = this.getImageFrameEl().querySelectorAll('.badge');
    [].map.call(existingBadges, badge => badge.remove());

    // Remove existing references to old view image badges
    this.imageBadges = [];

    // Image_file.js has a fade animation of 200ms for loading the view
    // Need to wait an additional 250ms for the images to be displayed
    // on window in order to re-normalize their dimensions
    setTimeout(() => {
      // Generate badge coordinates on new view
      this.renderBadges();

      // Re-render indicator in new view
      if (indicator.removed) {
        const normalizedIndicator = imageDiffHelper.resizeCoordinatesToImageElement(this.getImageEl(), {
          x: indicator.x,
          y: indicator.y,
          width: indicator.image.width,
          height: indicator.image.height,
        });
        imageDiffHelper.showCommentIndicator(this.getImageFrameEl(), normalizedIndicator);
      }
    }, 250);
  }
}
