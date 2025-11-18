import { htmlEncode } from '~/lib/utils/html';

describe('html utility', () => {
  describe('htmlEncode', () => {
    it('encodes ampersand characters', () => {
      expect(htmlEncode('A & B & C')).toBe('A &amp; B &amp; C');
    });

    it('encodes less-than and greater-than characters', () => {
      expect(htmlEncode('<script>')).toBe('&lt;script&gt;');
    });

    it('encodes single quote characters', () => {
      expect(htmlEncode("It's a beautiful day")).toBe('It&apos;s a beautiful day');
    });

    it('encodes double quote characters', () => {
      expect(htmlEncode('Say "Hello"')).toBe('Say &quot;Hello&quot;');
    });

    it('encodes multiple special characters in the same string', () => {
      expect(htmlEncode('<script>alert("XSS")</script>')).toBe(
        '&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;',
      );
    });

    it('handles empty string input', () => {
      expect(htmlEncode('')).toBe('');
    });

    it('handles undefined input with default parameter', () => {
      expect(htmlEncode()).toBe('');
    });

    it('preserves whitespace and newlines', () => {
      expect(htmlEncode('Hello\nWorld')).toBe('Hello\nWorld');
      expect(htmlEncode('Hello\tWorld')).toBe('Hello\tWorld');
      expect(htmlEncode('  Hello World  ')).toBe('  Hello World  ');
    });

    it('handles complex HTML-like structures', () => {
      const input =
        '<html><head><title>Page & Title</title></head>' +
        '<body><p class="text">Hello "World"!</p></body></html>';
      const expected =
        '&lt;html&gt;&lt;head&gt;&lt;title&gt;Page &amp; Title&lt;/title&gt;&lt;' +
        '/head&gt;&lt;body&gt;&lt;p class=&quot;text&quot;&gt;Hello &quot;World&quot;!&lt;' +
        '/p&gt;&lt;/body&gt;&lt;/html&gt;';
      expect(htmlEncode(input)).toBe(expected);
    });

    it('handles JavaScript code snippets', () => {
      const input = 'if (x < 5 && y > 10) { alert("Hello & Goodbye"); }';
      const expected =
        'if (x &lt; 5 &amp;&amp; y &gt; 10) { alert(&quot;Hello &amp; Goodbye&quot;); }';
      expect(htmlEncode(input)).toBe(expected);
    });

    it('handles SQL injection attempts', () => {
      const input = "'; DROP TABLE users; --";
      const expected = '&apos;; DROP TABLE users; --';
      expect(htmlEncode(input)).toBe(expected);
    });

    it('handles XSS attack vectors', () => {
      const xssVectors = [
        '<script>alert(1)</script>',
        '<img src="x" onerror="alert(1)">',
        '<svg onload="alert(1)">',
        '<iframe src="javascript:alert(1)"></iframe>',
      ];

      xssVectors.forEach((vector) => {
        const encoded = htmlEncode(vector);
        expect(encoded).not.toContain('<script');
        expect(encoded).not.toContain('<img');
        expect(encoded).not.toContain('<svg');
        expect(encoded).not.toContain('<iframe');
        expect(encoded).toContain('&lt;');
        expect(encoded).toContain('&gt;');
      });
    });

    it('handles Unicode characters correctly', () => {
      expect(htmlEncode('Hello 世界 & "Universe"')).toBe('Hello 世界 &amp; &quot;Universe&quot;');
      expect(htmlEncode('Café & "Restaurant"')).toBe('Café &amp; &quot;Restaurant&quot;');
      expect(htmlEncode('🚀 < 🌟')).toBe('🚀 &lt; 🌟');
    });
  });
});
