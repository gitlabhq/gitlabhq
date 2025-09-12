import { formatMarkdownTable } from '~/lib/utils/markdown_table_cleanup';

describe('MarkdownTableCleanup', () => {
  it('formats a simple table', () => {
    const input = ['| Col 1 | Col 2 |', '|---- |---- |', '| first column | second column |'].join(
      '\n',
    );

    const output = [
      '| Col 1        | Col 2         |',
      '|--------------|---------------|',
      '| first column | second column |',
    ].join('\n');

    expect(formatMarkdownTable(input)).toBe(output);
  });

  it('formats an indented table', () => {
    const input = [
      '  | Col 1 | Col 2 |',
      '  |---- |---- |',
      '  | first column | second column |',
    ].join('\n');

    const output = [
      '  | Col 1        | Col 2         |',
      '  |--------------|---------------|',
      '  | first column | second column |',
    ].join('\n');

    expect(formatMarkdownTable(input)).toBe(output);
  });

  it('adds a header row if one does not exist', () => {
    const input = ['|---- |---- |', '| first column | second column |'].join('\n');

    const output = [
      '|              |               |',
      '|--------------|---------------|',
      '| first column | second column |',
    ].join('\n');

    expect(formatMarkdownTable(input)).toBe(output);
  });

  it('tests alignment chars', () => {
    const input = [
      '| left    | centered  | right |',
      '|---- |:----:|----------------:|',
      '| 1 | 123 | 45 |',
    ].join('\n');

    const output = [
      '| left | centered | right |',
      '|------|:--------:|------:|',
      '| 1    |   123    |    45 |',
    ].join('\n');

    expect(formatMarkdownTable(input)).toBe(output);
  });

  it('allows an empty header row', () => {
    const input = ['|||', '|---- |---- |', '| first column | second column |'].join('\n');

    const output = [
      '|              |               |',
      '|--------------|---------------|',
      '| first column | second column |',
    ].join('\n');

    expect(formatMarkdownTable(input)).toBe(output);
  });

  describe('empty and null input edge cases', () => {
    it('handles empty string input', () => {
      expect(formatMarkdownTable('')).toBe('');
    });

    it('handles null input gracefully', () => {
      expect(() => formatMarkdownTable(null)).not.toThrow();
    });

    it('handles undefined input gracefully', () => {
      expect(() => formatMarkdownTable(undefined)).not.toThrow();
    });

    it('handles whitespace-only input', () => {
      const input = '   \n  \n   ';
      expect(formatMarkdownTable(input)).toBe(input);
    });

    it('handles input with no table content', () => {
      const input = 'This is just regular text\nwith no tables at all.';
      expect(formatMarkdownTable(input)).toBe(input);
    });
  });

  describe('malformed table structures', () => {
    it('handles table with missing opening pipe', () => {
      const input = ['Col 1 | Col 2 |', '|---- |---- |', '| first column | second column |'].join(
        '\n',
      );
      const output = [
        'Col 1 | Col 2 |',
        '|              |               |',
        '|--------------|---------------|',
        '| first column | second column |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles table with missing closing pipe', () => {
      const input = ['| Col 1 | Col 2', '|---- |---- |', '| first column | second column |'].join(
        '\n',
      );
      const output = [
        '| Col 1 | Col 2',
        '|              |               |',
        '|--------------|---------------|',
        '| first column | second column |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles incomplete table with only header row', () => {
      const input = '| Col 1 | Col 2 |';
      // Should not be formatted as a table without separator
      expect(formatMarkdownTable(input)).toBe('');
    });

    it('incomplete table with other text', () => {
      const input = ['| Col 1 | Col 2 |', 'foo'].join('\n');
      // Should not be formatted as a table without separator
      expect(formatMarkdownTable(input)).toBe('');
    });

    it('handles table with only separator row', () => {
      const input = '|---- |---- |';
      expect(formatMarkdownTable(input)).toBe('');
    });

    it('handles table with malformed separator (no dashes)', () => {
      const input = [
        '| Col 1 | Col 2 |',
        '|      |      |',
        '| first column | second column |',
      ].join('\n');
      // Should not be recognized as a table separator
      expect(formatMarkdownTable(input)).toBe('');
    });

    it('handles table with extra pipes in cells', () => {
      const input = [
        '| Col | 1 | Col 2 |',
        '|---- |---- |',
        '| first | column | second column |',
      ].join('\n');
      const output = [
        '| Col   | 1      | Col 2         |',
        '|-------|--------|---------------|',
        '| first | column | second column |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });
  });

  describe('inconsistent column count scenarios', () => {
    it('handles rows with fewer columns than header', () => {
      const input = ['| Col 1 | Col 2 | Col 3 |', '|---- |---- |---- |', '| first | second |'].join(
        '\n',
      );
      const output = [
        '| Col 1 | Col 2  | Col 3 |',
        '|-------|--------|-------|',
        '| first | second |       |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles rows with more columns than header', () => {
      const input = [
        '| Col 1 | Col 2 |',
        '|---- |---- |',
        '| first | second | third | fourth |',
      ].join('\n');
      const output = [
        '| Col 1 | Col 2  |       |        |',
        '|-------|--------|-------|--------|',
        '| first | second | third | fourth |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles separator with different column count than data rows', () => {
      const input = [
        '| Col 1 | Col 2 | Col 3 |',
        '|---- |---- |',
        '| first | second | third |',
      ].join('\n');
      const output = [
        '| Col 1 | Col 2  | Col 3 |',
        '|-------|--------|-------|',
        '| first | second | third |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles empty cells in various positions', () => {
      const input = [
        '| Col 1 | Col 2 | Col 3 |',
        '|---- |---- |---- |',
        '| | second | |',
        '| first | | third |',
      ].join('\n');
      const output = [
        '| Col 1 | Col 2  | Col 3 |',
        '|-------|--------|-------|',
        '|       | second |       |',
        '| first |        | third |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles single column table', () => {
      const input = ['| Single Col |', '|---- |', '| value 1 |', '| value 2 |'].join('\n');
      const output = ['| Single Col |', '|------------|', '| value 1    |', '| value 2    |'].join(
        '\n',
      );
      expect(formatMarkdownTable(input)).toBe(output);
    });
  });

  describe('special character handling', () => {
    it('handles HTML entities in table cells', () => {
      const input = ['| HTML | Entities |', '|---- |---- |', '| &lt;tag&gt; | &amp;nbsp; |'].join(
        '\n',
      );
      const output = [
        '| HTML        | Entities   |',
        '|-------------|------------|',
        '| &lt;tag&gt; | &amp;nbsp; |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles Unicode characters in table cells', () => {
      const input = ['| Unicode | Characters |', '|---- |---- |', '| 🚀 | ñáéíóú |'].join('\n');
      const output = [
        '| Unicode | Characters |',
        '|---------|------------|',
        '| 🚀      | ñáéíóú     |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles markdown syntax within table cells', () => {
      const input = [
        '| Markdown | Syntax |',
        '|---- |---- |',
        '| **bold** | `code` |',
        '| *italic* | [link](url) |',
      ].join('\n');
      const output = [
        '| Markdown | Syntax      |',
        '|----------|-------------|',
        '| **bold** | `code`      |',
        '| *italic* | [link](url) |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('handles escaped pipe characters in cells', () => {
      const input = [
        '| Pipes | Content |',
        '|---- |---- |',
        '| \\| escaped | normal \\| pipe |',
      ].join('\n');
      const output = [
        '| Pipes      | Content       |',
        '|------------|---------------|',
        '| \\| escaped | normal \\| pipe |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles newlines and line breaks in cells', () => {
      const input = [
        '| Multi | Line |',
        '|---- |---- |',
        '| line<br>break | content<br/>here |',
      ].join('\n');
      const output = [
        '| Multi         | Line             |',
        '|---------------|------------------|',
        '| line<br>break | content<br/>here |',
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });
  });

  describe('mixed content scenarios', () => {
    it('handles table mixed with regular text', () => {
      const input = [
        'This is some text before the table.',
        '',
        '| Col 1 | Col 2 |',
        '|---- |---- |',
        '| data1 | data2 |',
        '',
        'This is text after the table.',
      ].join('\n');

      const output = [
        'This is some text before the table.',
        '',
        '| Col 1 | Col 2 |',
        '|-------|-------|',
        '| data1 | data2 |',
        '',
        'This is text after the table.',
      ].join('\n');

      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles multiple tables in same text', () => {
      const input = [
        '| Table 1 | Col 2 |',
        '|---- |---- |',
        '| data1 | data2 |',
        '',
        'Some text between tables',
        '',
        '| Table 2 | Different |',
        '|---- |---- |',
        '| other | values |',
      ].join('\n');

      const output = [
        '| Table 1 | Col 2 |',
        '|---------|-------|',
        '| data1   | data2 |',
        '',
        'Some text between tables',
        '',
        '| Table 2 | Different |',
        '|---------|-----------|',
        '| other   | values    |',
      ].join('\n');

      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles tables with different indentation levels', () => {
      const input = [
        '| Normal table | Col 2 |',
        '|---- |---- |',
        '| data1 | data2 |',
        '',
        '    | Indented table | Col 2 |',
        '    |---- |---- |',
        '    | data1 | data2 |',
      ].join('\n');

      const output = [
        '| Normal table | Col 2 |',
        '|--------------|-------|',
        '| data1        | data2 |',
        '',
        '    | Indented table | Col 2 |',
        '    |----------------|-------|',
        '    | data1          | data2 |',
      ].join('\n');

      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles table at end of text without trailing newline', () => {
      const input = ['| Col 1 | Col 2 |', '|---- |---- |', '| data1 | data2 |'].join('\n');

      const output = ['| Col 1 | Col 2 |', '|-------|-------|', '| data1 | data2 |'].join('\n');

      expect(formatMarkdownTable(input)).toBe(output);
    });
  });

  describe('error conditions and boundary cases', () => {
    it('handles extremely long cell content', () => {
      const longContent = 'a'.repeat(1000);
      const input = ['| Short | Long |', '|---- |---- |', `| short | ${longContent} |`].join('\n');
      const output = [
        `| Short | Long${' '.repeat(996)} |`,
        `|-------|${'-'.repeat(1002)}|`,
        `| short | ${longContent} |`,
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles table with zero-width cells', () => {
      const input = ['| | |', '|---- |---- |', '| | |'].join('\n');
      const output = ['|  |  |', '|--|--|', '|  |  |'].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles table with only whitespace in cells', () => {
      const input = ['|   |   |', '|---- |---- |', '|   |   |'].join('\n');
      const output = ['|  |  |', '|--|--|', '|  |  |'].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles table with mixed line endings', () => {
      const input = '| Col 1 | Col 2 |\r\n|---- |---- |\r\n| data1 | data2 |';
      const output = ['| Col 1 | Col 2 |', '|-------|-------|', '| data1 | data2 |'].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles table with excessive whitespace around pipes', () => {
      const input = [
        '|    Col 1    |    Col 2    |',
        '|    ----    |    ----    |',
        '|    data1    |    data2    |',
      ].join('\n');
      const output = ['| Col 1 | Col 2 |', '|-------|-------|', '| data1 | data2 |'].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles deeply indented tables', () => {
      const indent = '        '; // 8 spaces
      const input = [
        `${indent}| Col 1 | Col 2 |`,
        `${indent}|---- |---- |`,
        `${indent}| data1 | data2 |`,
      ].join('\n');
      const output = [
        `${indent}| Col 1 | Col 2 |`,
        `${indent}|-------|-------|`,
        `${indent}| data1 | data2 |`,
      ].join('\n');
      expect(formatMarkdownTable(input)).toBe(output);
    });

    it('handles table with complex alignment combinations', () => {
      const input = [
        '| Left | Center | Right | Default |',
        '|:---- |:----:| ----:| ---- |',
        '| L | C | R | D |',
      ].join('\n');

      const output = [
        '| Left | Center | Right | Default |',
        '|------|:------:|------:|---------|',
        '| L    |   C    |     R | D       |',
      ].join('\n');

      expect(formatMarkdownTable(input)).toBe(output);
    });
  });
});
