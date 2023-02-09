import $ from 'jquery';

export const canScroll = () => $(document).height() > $(window).height();

/**
 * Checks if the entire page is scrolled down all the way to the bottom
 *  @returns {Boolean}
 */
export const isScrolledToBottom = () => {
  // Use clientHeight to account for any horizontal scrollbar.
  const { scrollHeight, scrollTop, clientHeight } = document.documentElement;

  // scrollTop can be a float, so round up to next integer.
  return Math.ceil(scrollTop + clientHeight) >= scrollHeight;
};

/**
 * Checks if page is scrolled to the top
 * @returns {Boolean}
 */
export const isScrolledToTop = () => $(document).scrollTop() === 0;

export const scrollDown = () => {
  const $document = $(document);
  $document.scrollTop($document.height());
};

export const scrollUp = () => {
  $(document).scrollTop(0);
};
