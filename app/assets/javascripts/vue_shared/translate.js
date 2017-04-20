import locale from '../locale';

export default (Vue) => {
  Vue.filter('translate', text => locale.gettext(text));

  Vue.filter('translate-plural', (text, pluralText, count) =>
    locale.ngettext(text, pluralText, count).replace(/%d/g, count));

  Vue.directive('translate', {
    bind(el) {
      const $el = el;
      const text = $el.textContent.trim();

      $el.textContent = locale.gettext(text);
    },
  });
};
