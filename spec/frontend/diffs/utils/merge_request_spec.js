import {
  updateChangesTabCount,
  getDerivedMergeRequestInformation,
} from '~/diffs/utils/merge_request';
import { ZERO_CHANGES_ALT_DISPLAY } from '~/diffs/constants';
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

  describe('updateChangesTabCount', () => {
    let dummyTab;
    let badge;

    beforeEach(() => {
      dummyTab = document.createElement('div');
      dummyTab.classList.add('js-diffs-tab');
      dummyTab.insertAdjacentHTML('afterbegin', '<span class="gl-badge">ERROR</span>');
      badge = dummyTab.querySelector('.gl-badge');
    });

    afterEach(() => {
      dummyTab.remove();
      dummyTab = null;
      badge = null;
    });

    it('uses the alt hyphen display when the new changes are falsey', () => {
      updateChangesTabCount({ count: 0, badge });

      expect(dummyTab.textContent).toBe(ZERO_CHANGES_ALT_DISPLAY);

      updateChangesTabCount({ badge });

      expect(dummyTab.textContent).toBe(ZERO_CHANGES_ALT_DISPLAY);

      updateChangesTabCount({ count: false, badge });

      expect(dummyTab.textContent).toBe(ZERO_CHANGES_ALT_DISPLAY);
    });

    it('uses the actual value for display when the value is truthy', () => {
      updateChangesTabCount({ count: 42, badge });

      expect(dummyTab.textContent).toBe('42');

      updateChangesTabCount({ count: '999+', badge });

      expect(dummyTab.textContent).toBe('999+');
    });

    it('selects the proper element to modify by default', () => {
      document.body.insertAdjacentElement('afterbegin', dummyTab);

      updateChangesTabCount({ count: 42 });

      expect(dummyTab.textContent).toBe('42');
    });
  });

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
