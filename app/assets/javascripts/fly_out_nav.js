export const calculateTop = (boundingRect, outerHeight) => {
  const windowHeight = window.innerHeight;
  const bottomOverflow = windowHeight - (boundingRect.top + outerHeight);

  return bottomOverflow < 0 ? (boundingRect.top - outerHeight) + boundingRect.height :
    boundingRect.top;
};

export default () => {
  $('.sidebar-top-level-items > li:not(.active)').on('mouseover', (e) => {
    const $this = e.currentTarget;
    const $subitems = $('.sidebar-sub-level-items', $this).show();

    if ($subitems.length) {
      const boundingRect = $this.getBoundingClientRect();
      const top = calculateTop(boundingRect, $subitems.outerHeight());
      const isAbove = top < boundingRect.top;

      $subitems.css({
        transform: `translate3d(0, ${top}px, 0)`,
      });

      if (isAbove) {
        $subitems.addClass('is-above');
      }
    }
  }).on('mouseout', e => $('.sidebar-sub-level-items', e.currentTarget).hide().removeClass('is-above'));
};
