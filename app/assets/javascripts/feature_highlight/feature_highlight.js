import Cookies from 'js-cookie';
import _ from 'underscore';
import bp from '../breakpoints';
import {
  getCookieName,
  getSelector,
  hidePopover,
  setupDismissButton,
  mouseenter,
  mouseleave,
} from './feature_highlight_helper';

export const highlightOrder = ['issue-boards'];

export function setupPopover(id, debounceTimeout = 300) {
  const $selector = $(getSelector(id));
  const $parent = $selector.parent();
  const $popoverContent = $parent.siblings('.feature-highlight-popover-content');
  const hideOnScroll = hidePopover.bind($selector);
  const debouncedMouseleave = _.debounce(mouseleave, debounceTimeout);

  $selector
    // Setup popover
    .data('content', $popoverContent.prop('outerHTML'))
    .popover({
      html: true,
      // Override the existing template to add custom CSS classes
      template: `
        <div class="popover feature-highlight-popover" role="tooltip">
          <div class="arrow"></div>
          <div class="popover-content"></div>
        </div>
      `,
    })
    .on('mouseenter', mouseenter)
    .on('mouseleave', debouncedMouseleave)
    .on('inserted.bs.popover', setupDismissButton)
    .on('show.bs.popover', () => {
      window.addEventListener('scroll', hideOnScroll);
    })
    .on('hide.bs.popover', () => {
      window.removeEventListener('scroll', hideOnScroll);
    })
    // Display feature highlight
    .removeAttr('disabled');
}

export function shouldHighlightFeature(id) {
  const element = document.querySelector(getSelector(id));
  const previouslyDismissed = Cookies.get(getCookieName(id)) === 'true';

  return element && !previouslyDismissed;
}

export function highlightFeatures(features) {
  const featureId = features.find(shouldHighlightFeature);

  if (featureId) {
    setupPopover(featureId);
    return true;
  }

  return false;
}

export function init(order) {
  if (bp.getBreakpointSize() === 'lg') {
    highlightFeatures(order);
  }
}
