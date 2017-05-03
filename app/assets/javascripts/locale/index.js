import Jed from 'jed';

function requireAll(requireContext) { return requireContext.keys().map(requireContext); }

const allLocales = requireAll(require.context('./', true, /^(?!.*(?:index.js$)).*\.js$/));
const locales = allLocales.reduce((d, obj) => {
  const data = d;
  const localeKey = Object.keys(obj)[0];

  data[localeKey] = obj[localeKey];

  return data;
}, {});

const lang = document.querySelector('html').getAttribute('lang').replace(/-/g, '_') || 'en';
const locale = new Jed(locales[lang]);
const gettext = locale.gettext.bind(locale);
const ngettext = locale.ngettext.bind(locale);
const pgettext = (context, key) => {
  const joinedKey = [context, key].join('|');
  return gettext(joinedKey).split('|').pop();
};

export { lang };
export { gettext as __ };
export { ngettext as n__ };
export { pgettext as s__ };
export default locale;
