import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';
import { diffMetadata } from '../mock_data/diff_metadata';

describe('Merge Request utilities', () => {
  const derivedBaseInfo = {
    mrPath: '/gitlab-org/gitlab-test/-/merge_requests/4',
    userOrGroup: 'gitlab-org',
    project: 'gitlab-test',
    id: '4',
  };
  const derivedVersionInfo = {
    diffId: '4',
    startSha: 'eb227b3e214624708c474bdab7bde7afc17cefcc',
  };
  const noVersion = {
    diffId: undefined,
    startSha: undefined,
  };
  const unparseableEndpoint = {
    mrPath: undefined,
    userOrGroup: undefined,
    project: undefined,
    id: undefined,
    ...noVersion,
  };

  describe('getDerivedMergeRequestInformation', () => {
    let endpoint = `${diffMetadata.latest_version_path}.json?searchParam=irrelevant`;

    it.each`
      argument                   | response
      ${{ endpoint }}            | ${{ ...derivedBaseInfo, ...noVersion }}
      ${{}}                      | ${unparseableEndpoint}
      ${{ endpoint: undefined }} | ${unparseableEndpoint}
      ${{ endpoint: null }}      | ${unparseableEndpoint}
    `('generates the correct derived results based on $argument', ({ argument, response }) => {
      expect(getDerivedMergeRequestInformation(argument)).toStrictEqual(response);
    });

    describe('version information', () => {
      const bare = diffMetadata.latest_version_path;
      endpoint = diffMetadata.merge_request_diffs[0].compare_path;

      it('still gets the correct derived information', () => {
        expect(getDerivedMergeRequestInformation({ endpoint })).toMatchObject(derivedBaseInfo);
      });

      it.each`
        url                                                   | versionPart
        ${endpoint}                                           | ${derivedVersionInfo}
        ${`${bare}?diff_id=${derivedVersionInfo.diffId}`}     | ${{ ...derivedVersionInfo, startSha: undefined }}
        ${`${bare}?start_sha=${derivedVersionInfo.startSha}`} | ${{ ...derivedVersionInfo, diffId: undefined }}
      `(
        'generates the correct derived version information based on $url',
        ({ url, versionPart }) => {
          expect(getDerivedMergeRequestInformation({ endpoint: url })).toMatchObject(versionPart);
        },
      );

      it('extracts nothing if there is no available version-like information in the URL', () => {
        expect(getDerivedMergeRequestInformation({ endpoint: bare })).toMatchObject(noVersion);
      });
    });
  });
});
