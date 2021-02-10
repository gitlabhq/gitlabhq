import { getErrorMessage, UNEXPECTED_ERROR } from '~/snippets/utils/error';

describe('~/snippets/utils/error', () => {
  describe('getErrorMessage', () => {
    it.each`
      input                                              | output
      ${null}                                            | ${UNEXPECTED_ERROR}
      ${'message'}                                       | ${'message'}
      ${new Error('test message')}                       | ${'test message'}
      ${{ networkError: 'Network error: test message' }} | ${'Network error: test message'}
      ${{}}                                              | ${UNEXPECTED_ERROR}
    `('with $input, should return "$output"', ({ input, output }) => {
      expect(getErrorMessage(input)).toBe(output);
    });
  });
});
