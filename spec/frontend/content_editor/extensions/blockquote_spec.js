import { multilineInputRegex } from '~/content_editor/extensions/blockquote';

describe('content_editor/extensions/blockquote', () => {
  describe.each`
    input       | matches
    ${'>>> '}   | ${true}
    ${' >>> '}  | ${true}
    ${'\t>>> '} | ${true}
    ${'>> '}    | ${false}
    ${'>>>x '}  | ${false}
    ${'> '}     | ${false}
  `('multilineInputRegex', ({ input, matches }) => {
    it(`${matches ? 'matches' : 'does not match'}: "${input}"`, () => {
      const match = new RegExp(multilineInputRegex).test(input);

      expect(match).toBe(matches);
    });
  });
});
