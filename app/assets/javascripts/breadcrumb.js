import $ from 'jquery';

export const addTooltipToEl = (el) => {
  const textEl = el.querySelector('.js-breadcrumb-item-text');

  if (textEl && textEl.scrollWidth > textEl.offsetWidth) {
    el.setAttribute('title', el.textContent);
    el.setAttribute('data-container', 'body');
    el.classList.add('has-tooltip');
  }
};

export default () => {
  const breadcrumbs = document.querySelector('.js-breadcrumbs-list');

  if (breadcrumbs) {
    const topLevelLinks = [...breadcrumbs.children].filter(el => !el.classList.contains('dropdown'))
      .map(el => el.querySelector('a'))
      .filter(el => el);
    const $expander = $('.js-breadcrumbs-collapsed-expander');

    topLevelLinks.forEach(el => addTooltipToEl(el));

    $expander.closest('.dropdown')
      .on('show.bs.dropdown hide.bs.dropdown', (e) => {
        $('.js-breadcrumbs-collapsed-expander', e.currentTarget).toggleClass('open')
          .tooltip('hide');
      });
  }
};
