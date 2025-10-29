// MD-JA001: Detects four consecutive asterisks (****)
// Pattern like ****text(unit)****

module.exports = {
  names: ['MD-JA001', 'no-four-asterisks'],
  description: 'Four consecutive asterisks (****) - likely a formatting error',
  tags: ['formatting', 'emphasis'],

  function: function rule(params, onError) {
    const { lines, tokens } = params;

    // Build a map of lines that are in code blocks or inline code
    const codeLines = new Set();
    const inlineCodeRanges = [];

    tokens.forEach((token) => {
      // Track fenced code blocks
      if (token.type === 'fence' || token.type === 'code_block') {
        const startLine = token.map[0];
        const endLine = token.map[1];
        for (let i = startLine; i < endLine; i++) {
          codeLines.add(i);
        }
      }

      // Track inline code
      if (token.type === 'inline' && token.children) {
        token.children.forEach((child) => {
          if (child.type === 'code_inline') {
            inlineCodeRanges.push({
              line: child.lineNumber - 1, // Convert to 0-indexed
              content: child.content,
            });
          }
        });
      }
    });

    lines.forEach((line, lineIndex) => {
      // Skip if entire line is in a code block
      if (codeLines.has(lineIndex)) {
        return;
      }

      // Find all occurrences of four or more asterisks
      const fourAsteriskPattern = /\*{4,}/g;
      let match;

      while ((match = fourAsteriskPattern.exec(line)) !== null) {
        // Check if this match is inside inline code
        const matchStart = match.index;
        const matchEnd = match.index + match[0].length;

        const isInInlineCode = inlineCodeRanges.some((range) => {
          if (range.line !== lineIndex) return false;

          // Check if the asterisks appear in this inline code section
          const codeStart = line.indexOf('`' + range.content);
          const codeEnd = codeStart + range.content.length + 2; // +2 for backticks

          return matchStart >= codeStart && matchEnd <= codeEnd;
        });

        if (isInInlineCode) {
          continue; // Skip if in inline code
        }

        const asteriskCount = match[0].length;
        const column = match.index + 1;

        let fixInfo = null;
        let detail = '';

        if (asteriskCount === 4) {
          const before = line.substring(0, match.index);
          const after = line.substring(match.index + 4);

          if (before.match(/[^\s*]$/) && after.match(/^[^\s*]/)) {
            fixInfo = {
              editColumn: column,
              deleteCount: 4,
              insertText: '** **',
            };
            detail = 'Should have space between closing and opening bold markers';
          } else {
            detail = 'Should be ** to close/open bold sections properly';
          }
        } else {
          detail = `Found ${asteriskCount} consecutive asterisks - check formatting`;
        }

        onError({
          lineNumber: lineIndex + 1,
          detail: detail,
          context: line.trim(),
          range: [column, asteriskCount],
          fixInfo: fixInfo,
        });
      }
    });
  },
};
