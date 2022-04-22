import { lowlight } from 'lowlight/lib/core';
import { __, sprintf } from '~/locale';
import CODE_BLOCK_LANGUAGES from '../constants/code_block_languages';

const codeBlockLanguageLoader = {
  lowlight,

  allLanguages: CODE_BLOCK_LANGUAGES,

  findLanguageBySyntax(value) {
    const lowercaseValue = value?.toLowerCase() || 'plaintext';
    return (
      this.allLanguages.find(
        ({ syntax, variants }) =>
          syntax === lowercaseValue || variants?.toLowerCase().split(', ').includes(lowercaseValue),
      ) || {
        syntax: lowercaseValue,
        label: sprintf(__(`Custom (%{language})`), { language: lowercaseValue }),
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
    const { syntax } = this.findLanguageBySyntax(match[1]);

    this.loadLanguages([syntax]);

    return { language: syntax };
  },

  loadLanguages(languageList = []) {
    const loaders = languageList
      .filter((languageName) => !this.isLanguageLoaded(languageName))
      .map((languageName) => {
        return import(
          /* webpackChunkName: 'highlight.language.js' */ `highlight.js/lib/languages/${languageName}`
        )
          .then(({ default: language }) => {
            this.lowlight.registerLanguage(languageName, language);
          })
          .catch(() => false);
      });

    return Promise.all(loaders);
  },
};

export default codeBlockLanguageLoader;
