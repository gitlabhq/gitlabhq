import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import { textblockTypeInputRule } from '@tiptap/core';
import { isFunction } from 'lodash';

const extractLanguage = (element) => element.getAttribute('lang');
const backtickInputRegex = /^```([a-z]+)?[\s\n]$/;
const tildeInputRegex = /^~~~([a-z]+)?[\s\n]$/;

const loadLanguageFromInputRule = (languageLoader) => (match) => {
  const language = match[1];

  if (isFunction(languageLoader?.loadLanguages)) {
    languageLoader.loadLanguages([language]);
  }

  return {
    language,
  };
};

export default CodeBlockLowlight.extend({
  isolating: true,

  addOptions() {
    return {
      ...this.parent?.(),
      languageLoader: {},
    };
  },

  addAttributes() {
    return {
      language: {
        default: null,
        parseHTML: (element) => extractLanguage(element),
      },
      class: {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        default: 'code highlight',
      },
    };
  },
  addInputRules() {
    const { languageLoader } = this.options;

    return [
      textblockTypeInputRule({
        find: backtickInputRegex,
        type: this.type,
        getAttributes: loadLanguageFromInputRule(languageLoader),
      }),
      textblockTypeInputRule({
        find: tildeInputRegex,
        type: this.type,
        getAttributes: loadLanguageFromInputRule(languageLoader),
      }),
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'pre',
      {
        ...HTMLAttributes,
        class: `content-editor-code-block ${HTMLAttributes.class}`,
      },
      ['code', {}, 0],
    ];
  },
});
