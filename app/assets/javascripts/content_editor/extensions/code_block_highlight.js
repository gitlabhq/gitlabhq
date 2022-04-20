import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import { textblockTypeInputRule } from '@tiptap/core';
import codeBlockLanguageLoader from '../services/code_block_language_loader';

const extractLanguage = (element) => element.getAttribute('lang');
export const backtickInputRegex = /^```([a-z]+)?[\s\n]$/;
export const tildeInputRegex = /^~~~([a-z]+)?[\s\n]$/;

export default CodeBlockLowlight.extend({
  isolating: true,
  exitOnArrowDown: false,

  addOptions() {
    return {
      ...this.parent?.(),
      languageLoader: codeBlockLanguageLoader,
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
    const getAttributes = (match) => languageLoader?.loadLanguageFromInputRule(match) || {};

    return [
      textblockTypeInputRule({
        find: backtickInputRegex,
        type: this.type,
        getAttributes,
      }),
      textblockTypeInputRule({
        find: tildeInputRegex,
        type: this.type,
        getAttributes,
      }),
    ];
  },
  parseHTML() {
    return [
      ...(this.parent?.() || []),
      {
        tag: 'div.markdown-code-block',
        skip: true,
      },
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'pre',
      {
        ...HTMLAttributes,
        class: `content-editor-code-block ${gon.user_color_scheme} ${HTMLAttributes.class}`,
      },
      ['code', {}, 0],
    ];
  },
});
