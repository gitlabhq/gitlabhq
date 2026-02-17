import { getDerivedMergeRequestInformation, extractFileHash } from '~/diffs/utils/merge_request';
import { diffMetadata } from '../mock_data/diff_metadata';

describe('Merge Request utilities', () => {
  const derivedBaseInfo = {
    mrPath: '/gitlab-org/gitlab-test/-/merge_requests/4',
    namespace: 'gitlab-org',
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
    namespace: undefined,
    project: undefined,
    id: undefined,
    ...noVersion,
  };

  describe('getDerivedMergeRequestInformation', () => {
    const bare = diffMetadata.latest_version_path;

    it.each`
      argument                                               | response
      ${{ endpoint: `${bare}.json?searchParam=irrelevant` }} | ${{ ...derivedBaseInfo, ...noVersion }}
      ${{}}                                                  | ${unparseableEndpoint}
      ${{ endpoint: undefined }}                             | ${unparseableEndpoint}
      ${{ endpoint: null }}                                  | ${unparseableEndpoint}
    `('generates the correct derived results based on $argument', ({ argument, response }) => {
      expect(getDerivedMergeRequestInformation(argument)).toStrictEqual(response);
    });

    describe('sub-group namespace', () => {
      it('extracts the entire namespace plus the project name', () => {
        const { namespace, project } = getDerivedMergeRequestInformation({
          endpoint: `/some/deep/path/of/groups${bare}`,
        });

        expect(namespace).toBe('some/deep/path/of/groups/gitlab-org');
        expect(project).toBe('gitlab-test');
      });
    });

    describe('version information', () => {
      it('still gets the correct derived information', () => {
        expect(
          getDerivedMergeRequestInformation({
            endpoint: diffMetadata.merge_request_diffs[0].compare_path,
          }),
        ).toMatchObject(derivedBaseInfo);
      });

      it.each`
        url                                                   | versionPart
        ${diffMetadata.merge_request_diffs[0].compare_path}   | ${derivedVersionInfo}
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

  describe('extractFileHash', () => {
    const sha1Like = 'abcdef1234567890abcdef1234567890abcdef12';
    const sha1LikeToo = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    it('returns undefined when a SHA1-like string cannot be found in the input', () => {
      expect(extractFileHash({ input: 'something' })).toBe(undefined);
    });

    it('returns the first matching string of SHA1-like characters in the input', () => {
      const fullString = `#${sha1Like}_34_42--${sha1LikeToo}`;

      expect(extractFileHash({ input: fullString })).toBe(sha1Like);
    });
  });
});
