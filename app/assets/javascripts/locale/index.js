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

export { lang };
export default new Jed(locales[lang]);
