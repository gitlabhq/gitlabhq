import { lowlight } from 'lowlight/lib/core';
import { __, sprintf } from '~/locale';
import CODE_BLOCK_LANGUAGES from '../constants/code_block_languages';
import languageLoader from './highlight_js_language_loader';

const codeBlockLanguageLoader = {
  lowlight,

  allLanguages: CODE_BLOCK_LANGUAGES,

  findOrCreateLanguageBySyntax(value, isDiagram) {
    const lowercaseValue = value?.toLowerCase() || 'plaintext';
    return (
      this.allLanguages.find(
        ({ syntax, variants }) =>
          syntax === lowercaseValue || variants?.toLowerCase().split(', ').includes(lowercaseValue),
      ) || {
        syntax: lowercaseValue,
        label: sprintf(isDiagram ? __(`Diagram (%{language})`) : __(`Custom (%{language})`), {
          language: lowercaseValue,
        }),
      }
    );
  },

  filterLanguages(value) {
    if (!value) return this.allLanguages;

    const lowercaseValue = value?.toLowerCase() || '';
    return this.allLanguages.filter(
      ({ syntax, label, variants }) =>
        syntax.toLowerCase().includes(lowercaseValue) ||
        label.toLowerCase().includes(lowercaseValue) ||
        variants?.toLowerCase().includes(lowercaseValue),
    );
  },

  isLanguageLoaded(language) {
    return this.lowlight.registered(language);
  },

  loadLanguageFromInputRule(match) {
    const { syntax } = this.findOrCreateLanguageBySyntax(match[1]);

    this.loadLanguage(syntax);

    return { language: syntax };
  },

  async loadLanguage(languageName) {
    if (this.isLanguageLoaded(languageName)) return false;

    try {
      const { default: language } = await languageLoader[languageName]();
      this.lowlight.registerLanguage(languageName, language);
      return true;
    } catch {
      return false;
    }
  },
};

export default codeBlockLanguageLoader;
