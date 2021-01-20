import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';
import { diffMetadata } from '../mock_data/diff_metadata';

describe('Merge Request utilities', () => {
  const derivedMrInfo = {
    mrPath: '/gitlab-org/gitlab-test/-/merge_requests/4',
    userOrGroup: 'gitlab-org',
    project: 'gitlab-test',
    id: '4',
  };
  const unparseableEndpoint = {
    mrPath: undefined,
    userOrGroup: undefined,
    project: undefined,
    id: undefined,
  };

  describe('getDerivedMergeRequestInformation', () => {
    const endpoint = `${diffMetadata.latest_version_path}.json?searchParam=irrelevant`;

    it.each`
      argument                   | response
      ${{ endpoint }}            | ${derivedMrInfo}
      ${{}}                      | ${unparseableEndpoint}
      ${{ endpoint: undefined }} | ${unparseableEndpoint}
      ${{ endpoint: null }}      | ${unparseableEndpoint}
    `('generates the correct derived results based on $argument', ({ argument, response }) => {
      expect(getDerivedMergeRequestInformation(argument)).toStrictEqual(response);
    });
  });
});
