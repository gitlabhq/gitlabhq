import Cookies from 'js-cookie';

export const getCookieName = cookieId => `feature-highlighted-${cookieId}`;
export const getSelector = highlightId => `.js-feature-highlight[data-highlight=${highlightId}]`;

export const showPopover = function showPopover() {
  if (this.hasClass('js-popover-show')) {
    return false;
  }
  this.popover('show');
  this.addClass('disable-animation js-popover-show');

  return true;
};

export const hidePopover = function hidePopover() {
  if (!this.hasClass('js-popover-show')) {
    return false;
  }
  this.popover('hide');
  this.removeClass('disable-animation js-popover-show');

  return true;
};

export const dismiss = function dismiss(cookieId) {
  Cookies.set(getCookieName(cookieId), true);
  hidePopover.call(this);
  this.hide();
};

export const mouseleave = function mouseleave() {
  if (!$('.popover:hover').length > 0) {
    const $featureHighlight = $(this);
    hidePopover.call($featureHighlight);
  }
};

export const mouseenter = function mouseenter() {
  const $featureHighlight = $(this);

  const showedPopover = showPopover.call($featureHighlight);
  if (showedPopover) {
    $('.popover')
      .on('mouseleave', mouseleave.bind($featureHighlight));
  }
};

export const setupDismissButton = function setupDismissButton() {
  const popoverId = this.getAttribute('aria-describedby');
  const cookieId = this.dataset.highlight;
  const $popover = $(this);
  const dismissWrapper = dismiss.bind($popover, cookieId);

  $(`#${popoverId} .dismiss-feature-highlight`)
    .on('click', dismissWrapper);
};
