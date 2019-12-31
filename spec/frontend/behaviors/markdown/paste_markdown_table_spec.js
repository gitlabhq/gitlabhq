import PasteMarkdownTable from '~/behaviors/markdown/paste_markdown_table';

describe('PasteMarkdownTable', () => {
  let data;

  beforeEach(() => {
    const event = new window.Event('paste');

    Object.defineProperty(event, 'dataTransfer', {
      value: {
        getData: jest.fn().mockImplementation(type => {
          if (type === 'text/html') {
            return '<table><tr><td></td></tr></table>';
          }
          return 'hello world';
        }),
      },
    });

    data = event.dataTransfer;
  });

  describe('isTable', () => {
    it('return false when no HTML data is provided', () => {
      data.types = ['text/plain'];

      expect(PasteMarkdownTable.isTable(data)).toBe(false);
    });

    it('returns false when no text data is provided', () => {
      data.types = ['text/html'];

      expect(PasteMarkdownTable.isTable(data)).toBe(false);
    });

    it('returns true when a table is provided in both text and HTML', () => {
      data.types = ['text/html', 'text/plain'];

      expect(PasteMarkdownTable.isTable(data)).toBe(true);
    });

    it('returns false when no HTML table is included', () => {
      data.types = ['text/html', 'text/plain'];
      data.getData = jest.fn().mockImplementation(() => 'nothing');

      expect(PasteMarkdownTable.isTable(data)).toBe(false);
    });
  });

  describe('convertToTableMarkdown', () => {
    let converter;

    beforeEach(() => {
      converter = new PasteMarkdownTable(data);
    });

    it('returns a Markdown table', () => {
      data.getData = jest.fn().mockImplementation(type => {
        if (type === 'text/plain') {
          return 'First\tLast\nJohn\tDoe\nJane\tDoe';
        }

        return '';
      });

      const expected = [
        '| First | Last |',
        '|-------|------|',
        '| John  | Doe  |',
        '| Jane  | Doe  |',
      ].join('\n');

      expect(converter.convertToTableMarkdown()).toBe(expected);
    });

    it('returns a Markdown table with rows normalized', () => {
      data.getData = jest.fn().mockImplementation(type => {
        if (type === 'text/plain') {
          return 'First\tLast\nJohn\tDoe\nJane';
        }

        return '';
      });

      const expected = [
        '| First | Last |',
        '|-------|------|',
        '| John  | Doe  |',
        '| Jane  |      |',
      ].join('\n');

      expect(converter.convertToTableMarkdown()).toBe(expected);
    });
  });
});
