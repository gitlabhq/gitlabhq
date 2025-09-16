const SCROLL_CONTAINER_SELECTOR = '.js-static-panel-inner';

const getScrollContainer = () => {
  return document.querySelector(SCROLL_CONTAINER_SELECTOR);
};

/**
 * Checks if container (or document if container is not found) is scrolled
 * down all the way to the bottom
 *
 * @returns {Boolean}
 */
export const isScrolledToBottom = (scrollContainer = getScrollContainer()) => {
  // Use clientHeight to account for any horizontal scrollbar.
  const { scrollHeight, scrollTop, clientHeight } = scrollContainer || document.documentElement;

  // scrollTop can be a float, so round up to next integer.
  return Math.ceil(scrollTop + clientHeight) >= scrollHeight;
};

/**
 * Checks if container (or document if container is not found) is scrolled to the top
 *
 * @returns {Boolean}
 */
export const isScrolledToTop = (scrollContainer = getScrollContainer()) => {
  const { scrollTop } = scrollContainer || document.documentElement;

  return scrollTop === 0;
};

export const scrollDown = (scrollContainer = getScrollContainer()) => {
  if (scrollContainer) {
    scrollContainer.scrollTo({ top: scrollContainer.scrollHeight });
  } else {
    window.scrollTo({ top: document.body.scrollHeight });
  }
};

export const scrollUp = (scrollContainer = getScrollContainer()) => {
  if (scrollContainer) {
    scrollContainer.scrollTo({ top: 0 });
  } else {
    window.scrollTo({ top: 0 });
  }
};
