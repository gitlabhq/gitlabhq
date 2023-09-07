import PasteMarkdownTable from '~/behaviors/markdown/paste_markdown_table';

describe('PasteMarkdownTable', () => {
  let data;

  beforeEach(() => {
    const event = new window.Event('paste');

    Object.defineProperty(event, 'dataTransfer', {
      value: {
        getData: jest.fn().mockImplementation((type) => {
          if (type === 'text/html') {
            return '<table><tr><td>First</td><td>Second</td></tr></table>';
          }
          return 'First\tSecond';
        }),
      },
    });

    data = event.dataTransfer;
  });

  describe('isTable', () => {
    it('return false when no HTML data is provided', () => {
      data.types = ['text/plain'];

      expect(new PasteMarkdownTable(data).isTable()).toBe(false);
    });

    it('returns false when no text data is provided', () => {
      data.types = ['text/html'];

      expect(new PasteMarkdownTable(data).isTable()).toBe(false);
    });

    it('returns true when a table is provided in both text and HTML', () => {
      data.types = ['text/html', 'text/plain'];

      expect(new PasteMarkdownTable(data).isTable()).toBe(true);
    });

    it('returns false when no HTML table is included', () => {
      data.types = ['text/html', 'text/plain'];
      data.getData = jest.fn().mockImplementation(() => 'nothing');

      expect(new PasteMarkdownTable(data).isTable()).toBe(false);
    });

    it('returns false when the number of rows are not consistent', () => {
      data.types = ['text/html', 'text/plain'];
      data.getData = jest.fn().mockImplementation((mimeType) => {
        if (mimeType === 'text/html') {
          return '<table><tr><td>def test<td></tr></table>';
        }
        return "def test\n  'hello'\n";
      });

      expect(new PasteMarkdownTable(data).isTable()).toBe(false);
    });

    it('returns false when the table copy comes from a diff', () => {
      data.types = ['text/html', 'text/plain'];
      data.getData = jest.fn().mockImplementation((mimeType) => {
        if (mimeType === 'text/html') {
          return '<table class="diff-wrap-lines"><tr><td>First</td><td>Second</td></tr></table>';
        }
        return 'First\tSecond';
      });

      expect(new PasteMarkdownTable(data).isTable()).toBe(false);
    });
  });

  describe('convertToTableMarkdown', () => {
    it('returns a Markdown table', () => {
      data.types = ['text/html', 'text/plain'];
      data.getData = jest.fn().mockImplementation((type) => {
        if (type === 'text/html') {
          return '<table><tr><td>First</td><td>Last</td><tr><td>John</td><td>Doe</td><tr><td>Jane</td><td>Doe</td></table>';
        }
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

      const converter = new PasteMarkdownTable(data);

      expect(converter.isTable()).toBe(true);
      expect(converter.convertToTableMarkdown()).toBe(expected);
    });

    it('returns a Markdown table with rows normalized', () => {
      data.types = ['text/html', 'text/plain'];
      data.getData = jest.fn().mockImplementation((type) => {
        if (type === 'text/html') {
          return '<table><tr><td>First</td><td>Last</td><tr><td>John</td><td>Doe</td><tr><td>Jane</td><td>/td></table>';
        }
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

      const converter = new PasteMarkdownTable(data);

      expect(converter.isTable()).toBe(true);
      expect(converter.convertToTableMarkdown()).toBe(expected);
    });
  });
});
