import { INVISIBLE, VISIBLE } from '~/rapid_diffs/adapter_events';
import { getScrollingElement, scrollTo } from '~/lib/utils/scroll_utils';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/common_utils';

function disableScrollToLink(e) {
  const link = e.target.closest('[data-line-number]');
  if (!link) return;
  e.preventDefault();
  const hash = link.href.split('#')[1];
  const target = document.getElementById(hash);
  // adding class on the client helps keep our markup lean for faster streaming
  target.classList.add(NO_SCROLL_TO_HASH_CLASS);
  const scrollingElement = getScrollingElement(link);
  const { scrollLeft, scrollTop } = scrollingElement;
  // replaceHistory won't highlight the element
  window.location.hash = hash;
  // prevent scrolling to the target element
  scrollTo({ top: scrollTop, left: scrollLeft });
  // the very top of the page behaves differently, we have to run this again
  if (scrollTop !== scrollingElement.scrollTop) {
    requestAnimationFrame(() => {
      scrollTo({ top: scrollTop, left: scrollLeft });
    });
  }
}

const getBody = (diffElement) => diffElement.querySelector('[data-file-body]');

export const lineLinkAdapter = {
  [VISIBLE]() {
    this.sink.disableScrollToLink = disableScrollToLink.bind(this);
    getBody(this.diffElement).addEventListener('click', this.sink.disableScrollToLink);
  },
  [INVISIBLE]() {
    if (this.sink.disableScrollToLink) {
      getBody(this.diffElement).removeEventListener('click', this.sink.disableScrollToLink);
    }
  },
};
