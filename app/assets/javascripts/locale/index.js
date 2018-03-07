import Jed from 'jed';
import sprintf from './sprintf';

const languageCode = () => document.querySelector('html').getAttribute('lang') || 'en';
const locale = new Jed(window.translations || {});
delete window.translations;

/**
  Translates `text`
  @param text The text to be translated
  @returns {String} The translated text
**/
const gettext = locale.gettext.bind(locale);

/**
  Translate the text with a number
  if the number is more than 1 it will use the `pluralText` translation.
  This method allows for contexts, see below re. contexts

  @param text Singular text to translate (eg. '%d day')
  @param pluralText Plural text to translate (eg. '%d days')
  @param count Number to decide which translation to use (eg. 2)
  @returns {String} Translated text with the number replaced (eg. '2 days')
**/
const ngettext = (text, pluralText, count) => {
  const translated = locale.ngettext(text, pluralText, count).replace(/%d/g, count).split('|');

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
**/
const pgettext = (keyOrContext, key) => {
  const normalizedKey = key ? `${keyOrContext}|${key}` : keyOrContext;
  const translated = gettext(normalizedKey).split('|');

  return translated[translated.length - 1];
};

/**
  Creates an instance of Intl.DateTimeFormat for the current locale.

  @param formatOptions for available options, please see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat
  @returns {Intl.DateTimeFormat}
*/
const createDateTimeFormat =
  formatOptions => Intl.DateTimeFormat(languageCode(), formatOptions);

export { languageCode };
export { gettext as __ };
export { ngettext as n__ };
export { pgettext as s__ };
export { sprintf };
export { createDateTimeFormat };
export default locale;
