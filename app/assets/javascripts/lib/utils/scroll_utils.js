import $ from 'jquery';

export const canScroll = () => $(document).height() > $(window).height();

/**
 * Checks if the entire page is scrolled down all the way to the bottom
 *  @returns {Boolean}
 */
export const isScrolledToBottom = () => {
  const $document = $(document);

  const currentPosition = $document.scrollTop();
  const scrollHeight = $document.height();

  const windowHeight = $(window).height();

  return scrollHeight - currentPosition === windowHeight;
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

/**
 * Checks if scroll position is in the middle of the page
 * @returns {Boolean}
 */
export const isScrolledToMiddle = () => {
  const $document = $(document);
  const currentPosition = $document.scrollTop();
  const scrollHeight = $document.height();
  const windowHeight = $(window).height();

  return currentPosition > 0 && scrollHeight - currentPosition !== windowHeight;
};

export const toggleDisableButton = ($button, disable) => {
  if (disable && $button.prop('disabled')) return;
  $button.prop('disabled', disable);
};
