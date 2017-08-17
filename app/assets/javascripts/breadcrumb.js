export const addTooltipToEl = (el) => {
  if (el.scrollWidth > el.offsetWidth) {
    el.setAttribute('title', el.textContent);
    el.setAttribute('data-container', 'body');
    el.classList.add('has-tooltip');
  }
};

export default () => {
  const breadcrumbs = document.querySelector('.breadcrumbs-list');
  const topLevelLinks = breadcrumbs.querySelectorAll('.breadcrumbs-list > li > a');
  const $expander = $('.js-breadcrumbs-collapsed-expander');

  topLevelLinks.forEach(el => addTooltipToEl(el));

  $expander.closest('.dropdown')
    .on('show.bs.dropdown hide.bs.dropdown', (e) => {
      $('.js-breadcrumbs-collapsed-expander', e.currentTarget).toggleClass('open')
        .tooltip('hide');
    });
};
