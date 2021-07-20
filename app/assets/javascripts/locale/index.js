import Jed from 'jed';
import ensureSingleLine from './ensure_single_line';
import sprintf from './sprintf';

const GITLAB_FALLBACK_LANGUAGE = 'en';

const languageCode = () =>
  document.querySelector('html').getAttribute('lang') || GITLAB_FALLBACK_LANGUAGE;
const locale = new Jed(window.translations || {});
delete window.translations;

/**
  Translates `text`
  @param text The text to be translated
  @returns {String} The translated text
*/
const gettext = (text) => locale.gettext(ensureSingleLine(text));

/**
  Translate the text with a number
  if the number is more than 1 it will use the `pluralText` translation.
  This method allows for contexts, see below re. contexts

  @param text Singular text to translate (eg. '%d day')
  @param pluralText Plural text to translate (eg. '%d days')
  @param count Number to decide which translation to use (eg. 2)
  @returns {String} Translated text with the number replaced (eg. '2 days')
*/
const ngettext = (text, pluralText, count) => {
  const translated = locale
    .ngettext(ensureSingleLine(text), ensureSingleLine(pluralText), count)
    .replace(/%d/g, count)
    .split('|');

  return translated[translated.length - 1];
};

/**
  Translate context based text
  Either pass in the context translation like `Context|Text to translate`
  or allow for dynamic text by doing passing in the context first & then the text to translate

  @param keyOrContext Can be either the key to translate including the context
                      (eg. 'Context|Text') or just the context for the translation
                      (eg. 'Context')
  @param key Is the dynamic variable you want to be translated
  @returns {String} Translated context based text
*/
const pgettext = (keyOrContext, key) => {
  const normalizedKey = ensureSingleLine(key ? `${keyOrContext}|${key}` : keyOrContext);
  const translated = gettext(normalizedKey).split('|');

  return translated[translated.length - 1];
};

/**
 * Filters navigator languages by the set GitLab language.
 *
 * This allows us to decide better what a user wants as a locale, for using with the Intl browser APIs.
 * If they have set their GitLab to a language, it will check whether `navigator.languages` contains matching ones.
 * This function always adds `en` as a fallback in order to have date renders if all fails before it.
 *
 * - Example one: GitLab language is `en` and browser languages are:
 *   `['en-GB', 'en-US']`. This function returns `['en-GB', 'en-US', 'en']` as
 *   the preferred locales, the Intl APIs would try to format first as British English,
 *   if that isn't available US or any English.
 * - Example two: GitLab language is `en` and browser languages are:
 *   `['de-DE', 'de']`. This function returns `['en']`, so the Intl APIs would prefer English
 *   formatting in order to not have German dates mixed with English GitLab UI texts.
 *   If the user wants for example British English formatting (24h, etc),
 *   they could set their browser languages to `['de-DE', 'de', 'en-GB']`.
 * - Example three: GitLab language is `de` and browser languages are `['en-US', 'en']`.
 *   This function returns `['de', 'en']`, aligning German dates with the chosen translation of GitLab.
 *
 * @returns {string[]}
 */
export const getPreferredLocales = () => {
  const gitlabLanguage = languageCode();
  // The GitLab language may or may not contain a country code,
  // so we create the short version as well, e.g. de-AT => de
  const lang = gitlabLanguage.substring(0, 2);
  const locales = navigator.languages.filter((l) => l.startsWith(lang));
  if (!locales.includes(gitlabLanguage)) {
    locales.push(gitlabLanguage);
  }
  if (!locales.includes(lang)) {
    locales.push(lang);
  }
  if (!locales.includes(GITLAB_FALLBACK_LANGUAGE)) {
    locales.push(GITLAB_FALLBACK_LANGUAGE);
  }
  return locales;
};

/**
  Creates an instance of Intl.DateTimeFormat for the current locale.

  @param formatOptions for available options, please see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat
  @returns {Intl.DateTimeFormat}
*/
const createDateTimeFormat = (formatOptions) =>
  Intl.DateTimeFormat(getPreferredLocales(), formatOptions);

/**
 * Formats a number as a string using `toLocaleString`.
 *
 * @param {Number} value - number to be converted
 * @param {options?} options - options to be passed to
 * `toLocaleString` such as `unit` and `style`.
 * @param {langCode?} langCode - If set, forces a different
 * language code from the one currently in the document.
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat/NumberFormat
 *
 * @returns If value is a number, the formatted value as a string
 */
function formatNumber(value, options = {}, langCode = languageCode()) {
  if (typeof value !== 'number' && typeof value !== 'bigint') {
    return value;
  }
  return value.toLocaleString(langCode, options);
}

export { languageCode };
export { gettext as __ };
export { ngettext as n__ };
export { pgettext as s__ };
export { sprintf };
export { createDateTimeFormat };
export { formatNumber };
export default locale;
