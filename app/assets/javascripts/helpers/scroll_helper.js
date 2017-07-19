function getScrollWidth() {
  const $rulerContainer = $('<div>').css({
    visibility: 'hidden',
    width: 100,
    overflow: 'scroll',
  });

  const $ruler = $('<div>').css({
    width: '100%',
  });

  $ruler.appendTo($rulerContainer);
  $rulerContainer.appendTo('body');

  const scrollWidth = $ruler.outerWidth();

  $rulerContainer.remove();

  return 100 - scrollWidth;
}

function setScrollWidth() {
  $('body').attr('data-scroll-width', getScrollWidth());
}

export {
  getScrollWidth,
  setScrollWidth,
};
