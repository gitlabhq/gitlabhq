import { lowlight } from 'lowlight/lib/core';
import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import { mergeAttributes, textblockTypeInputRule } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import languageLoader from '../services/code_block_language_loader';
import CodeBlockWrapper from '../components/wrappers/code_block.vue';

const extractLanguage = (element) => element.dataset.canonicalLang ?? element.getAttribute('lang');

export const backtickInputRegex = /^```([a-z]+)?[\s\n]$/;
export const tildeInputRegex = /^~~~([a-z]+)?[\s\n]$/;

export default CodeBlockLowlight.extend({
  isolating: true,
  exitOnArrowDown: false,

  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
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
      langParams: {
        default: null,
        parseHTML: (element) => element.dataset.langParams,
      },
    };
  },
  addInputRules() {
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
      {
        tag: 'div.markdown-code-block',
        skip: true,
      },
      {
        tag: 'pre.js-syntax-highlight',
        preserveWhitespace: 'full',
      },
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'pre',
      {
        ...mergeAttributes(this.options.HTMLAttributes, HTMLAttributes),
        class: `content-editor-code-block ${gon.user_color_scheme} ${HTMLAttributes.class}`,
      },
      ['code', {}, 0],
    ];
  },

  addNodeView() {
    return new VueNodeViewRenderer(CodeBlockWrapper);
  },

  addProseMirrorPlugins() {
    const parentPlugins = this.parent?.() ?? [];
    // We don't want TipTap's VSCode paste plugin to be loaded since
    // it conflicts with our CopyPaste plugin.
    const i = parentPlugins.findIndex((plugin) => plugin.key.includes('VSCode'));
    if (i >= 0) parentPlugins.splice(i, 1);
    return parentPlugins;
  },
}).configure({ lowlight });
