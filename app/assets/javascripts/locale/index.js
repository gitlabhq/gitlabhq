import Jed from 'jed';
import { de } from './de/app';
import { es } from './es/app';
import { en } from './en/app';

const locales = {
  de,
  es,
  en,
};

const lang = document.querySelector('html').getAttribute('lang') || 'en';
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
