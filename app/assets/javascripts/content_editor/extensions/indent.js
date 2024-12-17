import { Extension } from '@tiptap/core';
import CodeBlockHighlight from './code_block_highlight';
import CodeSuggestion from './code_suggestion';
import Diagram from './diagram';
import Frontmatter from './frontmatter';

export const INDENT_SPACES = '  ';

const CODE_BLOCK_NODE_TYPES = [
  CodeBlockHighlight.name,
  Diagram.name,
  Frontmatter.name,
  CodeSuggestion.name,
];

const isCodeBlockActive = (editor) => CODE_BLOCK_NODE_TYPES.some((type) => editor.isActive(type));

export default Extension.create({
  name: 'indent',

  addKeyboardShortcuts() {
    return {
      Tab: () => this.editor.commands.indentOrUnindentCodeBlock(true),
      'Shift-Tab': () => this.editor.commands.indentOrUnindentCodeBlock(false),
    };
  },

  addCommands() {
    return {
      indentOrUnindentCodeBlock:
        (indent) =>
        ({ state: { doc, selection }, editor, commands }) => {
          const { from, to, $from } = selection;
          if (!isCodeBlockActive(editor)) return false;
          if (from === to && indent) return commands.insertContent(INDENT_SPACES);

          const lineStart = from - doc.textBetween($from.start(), from).split('\n').pop().length;
          const selectedLines = doc.textBetween(lineStart, to).split('\n');

          if (selectedLines.length === 1 && !selectedLines[0].trim() && !indent) {
            const spaceAfter = doc.textBetween(from, $from.end()).match(/^\s*/)[0];
            if (spaceAfter.length) {
              return commands.deleteRange({
                from,
                to: from + Math.min(spaceAfter.length, INDENT_SPACES.length),
              });
            }
          }

          const indentLength = (line) =>
            indent
              ? INDENT_SPACES.length
              : -Math.min(INDENT_SPACES.length, line.match(/^(\s*)/)[0].length);

          let addedLength = 0;
          let pos = lineStart;
          selectedLines.forEach((line) => {
            if (indent) commands.insertContentAt(pos, INDENT_SPACES);
            else commands.deleteRange({ from: pos, to: pos - indentLength(line) });

            pos += indentLength(line) + line.length + 1;
            addedLength += indentLength(line);
          });

          const atStartOfLine = from === lineStart;
          return commands.setTextSelection({
            from: from + (atStartOfLine ? 0 : indentLength(selectedLines[0])),
            to: to + addedLength,
          });
        },
    };
  },
});
