import $ from 'jquery';

export const addTooltipToEl = (el) => {
  const textEl = el.querySelector('.js-breadcrumb-item-text');

  if (textEl && textEl.scrollWidth > textEl.offsetWidth) {
    el.setAttribute('title', el.textContent);
    el.dataset.container = 'body';
    el.classList.add('has-tooltip');
  }
};

export default () => {
  const breadcrumbs = document.querySelector('.js-breadcrumbs-list');

  if (breadcrumbs) {
    const topLevelLinks = [...breadcrumbs.children]
      .filter((el) => !el.classList.contains('dropdown'))
      .map((el) => el.querySelector('a'))
      .filter((el) => el);
    const $expanderBtn = $('.js-breadcrumbs-collapsed-expander');

    topLevelLinks.forEach((el) => addTooltipToEl(el));

    $expanderBtn.on('click', () => {
      const detailItems = $('.gl-breadcrumb-item');
      const hiddenClass = '!gl-hidden';

      $.each(detailItems, (_key, item) => {
        $(item).removeClass(hiddenClass);
      });

      // remove the ellipsis
      $('li.expander').remove();

      // set focus on first breadcrumb item
      $('.js-breadcrumb-item-text').first().focus();
    });
  }
};
