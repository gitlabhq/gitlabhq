import { computeSuggestionCommitMessage } from '~/diffs/utils/suggestions';

describe('Diff Suggestions utilities', () => {
  describe('computeSuggestionCommitMessage', () => {
    it.each`
      description                                                     | input              | values                        | output
      ${'makes the appropriate replacements'}                         | ${'%{foo} %{bar}'} | ${{ foo: 'foo', bar: 'bar' }} | ${'foo bar'}
      ${"skips replacing values that aren't passed"}                  | ${'%{foo} %{bar}'} | ${{ foo: 'foo' }}             | ${'foo %{bar}'}
      ${'treats the number 0 as a valid value (not falsey)'}          | ${'%{foo} %{bar}'} | ${{ foo: 'foo', bar: 0 }}     | ${'foo 0'}
      ${"works when the variables don't have any space between them"} | ${'%{foo}%{bar}'}  | ${{ foo: 'foo', bar: 'bar' }} | ${'foobar'}
    `('$description', ({ input, output, values }) => {
      expect(computeSuggestionCommitMessage({ message: input, values })).toBe(output);
    });
  });
});
