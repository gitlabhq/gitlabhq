import $ from 'jquery';
import _ from 'underscore';

export function togglePopover(show) {
  const $popover = $(this);
  const isAlreadyShown = $popover.hasClass('js-popover-show');
  if ((show && isAlreadyShown) || (!show && !isAlreadyShown)) {
    return false;
  }
  $popover.popover(show ? 'show' : 'hide');
  $popover.toggleClass('disable-animation js-popover-show', show);

  return true;
}

export function mouseleave() {
  if (!$('.popover:hover').length > 0) {
    const $popover = $(this);
    togglePopover.call($popover, false);
  }
}

export function mouseenter() {
  const $popover = $(this);

  const showedPopover = togglePopover.call($popover, true);
  if (showedPopover) {
    $('.popover').on('mouseleave', mouseleave.bind($popover));
  }
}

export function debouncedMouseleave(debounceTimeout = 300) {
  return _.debounce(mouseleave, debounceTimeout);
}
