import $ from 'jquery';

export const canScroll = () => $(document).height() > $(window).height();

export const isScrolledToBottom = () => {
  const $document = $(document);

  const currentPosition = $document.scrollTop();
  const scrollHeight = $document.height();

  const windowHeight = $(window).height();

  return scrollHeight - currentPosition === windowHeight;
};

export const scrollDown = () => {
  const $document = $(document);
  $document.scrollTop($document.height());
};

export const toggleDisableButton = ($button, disable) => {
  if (disable && $button.prop('disabled')) return;
  $button.prop('disabled', disable);
};

export default {};
