import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';
import { diffMetadata } from '../mock_data/diff_metadata';

describe('Merge Request utilities', () => {
  describe('getDerivedMergeRequestInformation', () => {
    const endpoint = `${diffMetadata.latest_version_path}.json?searchParam=irrelevant`;
    const mrPath = diffMetadata.latest_version_path.replace(/\/diffs$/, '');

    it.each`
      argument                   | response
      ${{ endpoint }}            | ${{ mrPath }}
      ${{}}                      | ${{ mrPath: undefined }}
      ${{ endpoint: undefined }} | ${{ mrPath: undefined }}
      ${{ endpoint: null }}      | ${{ mrPath: undefined }}
    `('generates the correct derived results based on $argument', ({ argument, response }) => {
      expect(getDerivedMergeRequestInformation(argument)).toStrictEqual(response);
    });
  });
});
