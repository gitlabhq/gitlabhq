import $ from 'jquery';
import axios from '../lib/utils/axios_utils';
import { __ } from '../locale';
import Flash from '../flash';
import LazyLoader from '../lazy_loader';
import { togglePopover, mouseenter, debouncedMouseleave } from '../shared/popover';

export const getSelector = highlightId => `.js-feature-highlight[data-highlight=${highlightId}]`;

export function dismiss(highlightId) {
  axios.post(this.attr('data-dismiss-endpoint'), {
    feature_name: highlightId,
  })
    .catch(() => Flash(__('An error occurred while dismissing the feature highlight. Refresh the page and try dismissing again.')));

  togglePopover.call(this, false);
  this.hide();
}

export function inserted() {
  const popoverId = this.getAttribute('aria-describedby');
  const highlightId = this.dataset.highlight;
  const $popover = $(this);
  const dismissWrapper = dismiss.bind($popover, highlightId);

  $(`#${popoverId} .dismiss-feature-highlight`)
    .on('click', dismissWrapper);

  const lazyImg = $(`#${popoverId} .feature-highlight-illustration`)[0];
  if (lazyImg) {
    LazyLoader.loadImage(lazyImg);
  }
}

export { togglePopover, mouseenter, debouncedMouseleave };
