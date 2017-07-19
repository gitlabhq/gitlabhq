import $ from 'jquery';

const ScrollHelper = {
  getScrollWidth() {
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
  },

  setScrollWidth() {
    $('body').attr('data-scroll-width', ScrollHelper.getScrollWidth());
  },
};

export default ScrollHelper;
