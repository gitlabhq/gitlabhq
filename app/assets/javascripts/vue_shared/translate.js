import locale from '../locale';

export default (Vue) => {
  Vue.filter('translate', text => locale.gettext(text));

  Vue.filter('translate-plural', (text, pluralText, count) =>
    locale.ngettext(text, pluralText, count).replace(/%d/g, count));
};
