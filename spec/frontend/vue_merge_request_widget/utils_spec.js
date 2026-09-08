import { rebaseFailureMessage } from '~/vue_merge_request_widget/utils';

describe('rebaseFailureMessage', () => {
  const genericMessage = 'Failed to rebase. Please try again.';

  it.each`
    description                             | error                                                                                    | expected
    ${'a reason without a trailing period'} | ${{ response: { data: { merge_error: 'Source branch is protected from force push' } } }} | ${'Failed to rebase: Source branch is protected from force push.'}
    ${'a reason with a trailing period'}    | ${{ response: { data: { merge_error: 'Cannot push to source branch.' } } }}              | ${'Failed to rebase: Cannot push to source branch.'}
    ${'a response without a reason'}        | ${{ response: { data: {} } }}                                                            | ${genericMessage}
    ${'a response without a body'}          | ${{ response: {} }}                                                                      | ${genericMessage}
    ${'an error without a response'}        | ${{}}                                                                                    | ${genericMessage}
    ${'no error at all'}                    | ${undefined}                                                                             | ${genericMessage}
  `('returns $expected for $description', ({ error, expected }) => {
    expect(rebaseFailureMessage(error)).toBe(expected);
  });
});
