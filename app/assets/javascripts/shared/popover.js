import $ from 'jquery';
import { debounce } from 'underscore';

export function togglePopover(show) {
  const isAlreadyShown = this.hasClass('js-popover-show');
  if ((show && isAlreadyShown) || (!show && !isAlreadyShown)) {
    return false;
  }
  this.popover(show ? 'show' : 'hide');
  this.toggleClass('disable-animation js-popover-show', show);

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
  return debounce(mouseleave, debounceTimeout);
}
