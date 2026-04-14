import { diffLineToString, pickDirection } from '~/diffs/utils/diff_line';

describe('diffs/utils/diff_line', () => {
  describe('diffLineToString', () => {
    it('returns text directly when present', () => {
      expect(diffLineToString({ text: 'plain text', rich_text: '<b>ignored</b>' })).toBe(
        'plain text',
      );
    });

    it('strips HTML tags from rich_text when text is absent', () => {
      expect(diffLineToString({ rich_text: '<span>hello</span>' })).toBe('hello');
    });

    it('unescapes HTML entities from rich_text', () => {
      expect(diffLineToString({ rich_text: '<span>&lt;div&gt;</span>' })).toBe('<div>');
    });

    it('replaces escaped newline sequences with %br', () => {
      expect(diffLineToString({ rich_text: '<span>hello\\nworld</span>' })).toBe('hello%brworld');
    });

    it('removes actual newline characters', () => {
      expect(diffLineToString({ rich_text: '<span>hello\nworld</span>' })).toBe('helloworld');
    });
  });

  describe('pickDirection', () => {
    it('returns left when no line_code matches', () => {
      const left = { line_code: 'a' };
      const right = { line_code: 'b' };
      expect(pickDirection({ line: { left, right }, code: 'x' })).toBe(left);
    });

    it('returns right when line_code matches right', () => {
      const left = { line_code: 'a' };
      const right = { line_code: 'b' };
      expect(pickDirection({ line: { left, right }, code: 'b' })).toBe(right);
    });
  });
});
