import { lowlight } from 'lowlight/lib/core';
import { textblockTypeInputRule } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import { memoizedGet } from '../services/utils';
import CodeBlockHighlight from './code_block_highlight';

const backtickInputRegex = /^```suggestion[\s\n]$/;

export default CodeBlockHighlight.extend({
  name: 'codeSuggestion',

  isolating: true,

  addOptions() {
    return {
      lowlight,
      codeSuggestionsConfig: {},
    };
  },

  addAttributes() {
    return {
      ...this.parent?.(),
      language: {
        default: 'suggestion',
      },
      isCodeSuggestion: {
        default: true,
      },
    };
  },

  addCommands() {
    const ext = this;

    return {
      insertCodeSuggestion:
        (attributes) =>
        async ({ editor }) => {
          // do not insert a new suggestion if already inside a suggestion
          if (editor.isActive('codeSuggestion')) return false;

          const rawPath = ext.options.codeSuggestionsConfig.diffFile.view_path.replace(
            '/blob/',
            '/raw/',
          );
          const allLines = (await memoizedGet(rawPath)).split('\n');
          const { line } = ext.options.codeSuggestionsConfig;
          let { lines } = ext.options.codeSuggestionsConfig;

          if (!lines.length) lines = [line];

          const content = lines.map((l) => allLines[l.new_line - 1]).join('\n');
          const lineNumbers = `-${lines.length - 1}+0`;

          editor.commands.insertContent({
            type: 'codeSuggestion',
            attrs: { langParams: lineNumbers, ...attributes },
            // empty strings are not allowed in text nodes
            content: [{ type: 'text', text: content || ' ' }],
          });

          return true;
        },
    };
  },

  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: 'pre[data-canonical-lang="suggestion"]',
      },
    ];
  },

  addInputRules() {
    return [
      textblockTypeInputRule({
        find: backtickInputRegex,
        type: this.type,
        getAttributes: () => ({ language: 'suggestion', langParams: '-0+0' }),
      }),
    ];
  },
});
