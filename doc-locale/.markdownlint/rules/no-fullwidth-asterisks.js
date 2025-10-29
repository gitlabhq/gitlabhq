// MD-JA002: Detect fullwidth asterisks and suggest halfwidth replacement
// Japanese input methods sometimes produce fullwidth ＊ instead of *

module.exports = {
  names: ['MD-JA002', 'no-fullwidth-asterisks'],
  description: 'Fullwidth asterisks (＊) should be halfwidth (*)',
  tags: ['formatting', 'japanese'],

  function: function rule(params, onError) {
    const { lines, tokens } = params;

    // Build a map of lines in code blocks
    const codeLines = new Set();
    const inlineCodeRanges = [];

    tokens.forEach((token) => {
      if (token.type === 'fence' || token.type === 'code_block') {
        const startLine = token.map[0];
        const endLine = token.map[1];
        for (let i = startLine; i < endLine; i++) {
          codeLines.add(i);
        }
      }

      if (token.type === 'inline' && token.children) {
        token.children.forEach((child) => {
          if (child.type === 'code_inline') {
            inlineCodeRanges.push({
              line: child.lineNumber - 1,
              content: child.content,
            });
          }
        });
      }
    });

    lines.forEach((line, lineIndex) => {
      // Skip code blocks
      if (codeLines.has(lineIndex)) {
        return;
      }

      const fullwidthPattern = /＊/g;
      let match;

      while ((match = fullwidthPattern.exec(line)) !== null) {
        // Check if in inline code
        const matchPos = match.index;
        const isInInlineCode = inlineCodeRanges.some((range) => {
          if (range.line !== lineIndex) return false;
          const codeStart = line.indexOf('`' + range.content);
          const codeEnd = codeStart + range.content.length + 2;
          return matchPos >= codeStart && matchPos <= codeEnd;
        });

        if (isInInlineCode) {
          continue;
        }

        const column = match.index + 1;

        onError({
          lineNumber: lineIndex + 1,
          detail: 'Fullwidth asterisk (＊) should be halfwidth (*)',
          context: line.trim(),
          range: [column, 1],
          fixInfo: {
            editColumn: column,
            deleteCount: 1,
            insertText: '*',
          },
        });
      }
    });
  },
};
