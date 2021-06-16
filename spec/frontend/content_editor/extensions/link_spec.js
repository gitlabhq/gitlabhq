import {
  markdownLinkSyntaxInputRuleRegExp,
  urlSyntaxRegExp,
  extractHrefFromMarkdownLink,
} from '~/content_editor/extensions/link';

describe('content_editor/extensions/link', () => {
  describe.each`
    input                             | matches
    ${'[gitlab](https://gitlab.com)'} | ${true}
    ${'[documentation](readme.md)'}   | ${true}
    ${'[link 123](readme.md)'}        | ${true}
    ${'[link 123](read me.md)'}       | ${true}
    ${'text'}                         | ${false}
    ${'documentation](readme.md'}     | ${false}
    ${'https://www.google.com'}       | ${false}
  `('markdownLinkSyntaxInputRuleRegExp', ({ input, matches }) => {
    it(`${matches ? 'matches' : 'does not match'} ${input}`, () => {
      const match = new RegExp(markdownLinkSyntaxInputRuleRegExp).exec(input);

      expect(Boolean(match?.groups.href)).toBe(matches);
    });
  });

  describe.each`
    input                        | matches
    ${'http://example.com '}     | ${true}
    ${'https://example.com '}    | ${true}
    ${'www.example.com '}        | ${true}
    ${'example.com/ab.html '}    | ${false}
    ${'text'}                    | ${false}
    ${' http://example.com '}    | ${true}
    ${'https://www.google.com '} | ${true}
  `('urlSyntaxRegExp', ({ input, matches }) => {
    it(`${matches ? 'matches' : 'does not match'} ${input}`, () => {
      const match = new RegExp(urlSyntaxRegExp).exec(input);

      expect(Boolean(match?.groups.href)).toBe(matches);
    });
  });

  describe('extractHrefFromMarkdownLink', () => {
    const input = '[gitlab](https://gitlab.com)';
    const href = 'https://gitlab.com';
    let match;
    let result;

    beforeEach(() => {
      match = new RegExp(markdownLinkSyntaxInputRuleRegExp).exec(input);
      result = extractHrefFromMarkdownLink(match);
    });

    it('extracts the url from a markdown link captured by markdownLinkSyntaxInputRuleRegExp', () => {
      expect(result).toEqual({ href });
    });

    it('makes sure that url text is the last capture group', () => {
      expect(match[match.length - 1]).toEqual('gitlab');
    });
  });
});
