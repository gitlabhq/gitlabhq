import locale from '../locale';

export default (Vue) => {
  Vue.filter('translate', text => locale.gettext(text));

  Vue.directive('translate', {
    bind(el) {
      const $el = el;
      const text = $el.textContent.trim();

      $el.textContent = locale.gettext(text);
    },
  });
};
