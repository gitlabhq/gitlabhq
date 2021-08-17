import { inputRegexAddition, inputRegexDeletion } from '~/content_editor/extensions/inline_diff';

describe('content_editor/extensions/inline_diff', () => {
  describe.each`
    inputRegex            | description             | input                         | matches
    ${inputRegexAddition} | ${'inputRegexAddition'} | ${'hello{+world+}'}           | ${true}
    ${inputRegexAddition} | ${'inputRegexAddition'} | ${'hello{+ world +}'}         | ${true}
    ${inputRegexAddition} | ${'inputRegexAddition'} | ${'hello {+ world+}'}         | ${true}
    ${inputRegexAddition} | ${'inputRegexAddition'} | ${'{+hello world +}'}         | ${true}
    ${inputRegexAddition} | ${'inputRegexAddition'} | ${'{+hello with \nnewline+}'} | ${false}
    ${inputRegexAddition} | ${'inputRegexAddition'} | ${'{+open only'}              | ${false}
    ${inputRegexAddition} | ${'inputRegexAddition'} | ${'close only+}'}             | ${false}
    ${inputRegexDeletion} | ${'inputRegexDeletion'} | ${'hello{-world-}'}           | ${true}
    ${inputRegexDeletion} | ${'inputRegexDeletion'} | ${'hello{- world -}'}         | ${true}
    ${inputRegexDeletion} | ${'inputRegexDeletion'} | ${'hello {- world-}'}         | ${true}
    ${inputRegexDeletion} | ${'inputRegexDeletion'} | ${'{-hello world -}'}         | ${true}
    ${inputRegexDeletion} | ${'inputRegexDeletion'} | ${'{+hello with \nnewline+}'} | ${false}
    ${inputRegexDeletion} | ${'inputRegexDeletion'} | ${'{-open only'}              | ${false}
    ${inputRegexDeletion} | ${'inputRegexDeletion'} | ${'close only-}'}             | ${false}
  `('$description', ({ inputRegex, input, matches }) => {
    it(`${matches ? 'matches' : 'does not match'}: "${input}"`, () => {
      const match = new RegExp(inputRegex).test(input);

      expect(match).toBe(matches);
    });
  });
});
