import { validateQueryString } from '~/ci/common/private/jobs_filtered_search/utils';

describe('Filtered search utils', () => {
  describe('validateQueryString', () => {
    it.each`
      queryStringObject                                        | expected
      ${{ statuses: 'SUCCESS' }}                               | ${{ statuses: 'SUCCESS' }}
      ${{ statuses: 'failed' }}                                | ${{ statuses: 'FAILED' }}
      ${{ runnerTypes: 'instance_type' }}                      | ${{ runnerTypes: 'INSTANCE_TYPE' }}
      ${{ runnerTypes: 'wrong_runner_type' }}                  | ${null}
      ${{ statuses: 'SUCCESS', runnerTypes: 'instance_type' }} | ${{ statuses: 'SUCCESS', runnerTypes: 'INSTANCE_TYPE' }}
      ${{ wrong: 'SUCCESS' }}                                  | ${null}
      ${{ statuses: 'wrong' }}                                 | ${null}
      ${{ wrong: 'wrong' }}                                    | ${null}
      ${{ name: 'rspec' }}                                     | ${{ name: 'rspec' }}
    `(
      'when provided $queryStringObject, the expected result is $expected',
      ({ queryStringObject, expected }) => {
        expect(validateQueryString(queryStringObject)).toEqual(expected);
      },
    );
  });
});
