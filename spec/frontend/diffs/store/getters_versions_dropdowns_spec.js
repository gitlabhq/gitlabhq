import {
  DIFF_COMPARE_BASE_VERSION_INDEX,
  DIFF_COMPARE_HEAD_VERSION_INDEX,
} from '~/diffs/constants';
import * as getters from '~/diffs/store/getters';
import state from '~/diffs/store/modules/diff_state';
import diffsMockData from '../mock_data/merge_request_diffs';

describe('Compare diff version dropdowns', () => {
  let localState;

  beforeEach(() => {
    localState = state();
    localState.mergeRequestDiff = {
      base_version_path: 'basePath',
      head_version_path: 'headPath',
      version_index: 1,
    };
    localState.targetBranchName = 'baseVersion';
    localState.mergeRequestDiffs = diffsMockData;
  });

  describe('selectedTargetIndex', () => {
    it('without startVersion', () => {
      expect(getters.selectedTargetIndex(localState)).toEqual(DIFF_COMPARE_BASE_VERSION_INDEX);
    });

    it('with startVersion', () => {
      const startVersion = { version_index: 1 };
      localState.startVersion = startVersion;
      expect(getters.selectedTargetIndex(localState)).toEqual(startVersion.version_index);
    });
  });

  it('selectedSourceIndex', () => {
    expect(getters.selectedSourceIndex(localState)).toEqual(
      localState.mergeRequestDiff.version_index,
    );
  });

  describe('diffCompareDropdownTargetVersions', () => {
    // diffCompareDropdownTargetVersions slices the array at the first position
    // and appends a "base" and "head" version at the end of the list so that
    // "base" and "head" appear at the bottom of the dropdown
    // this is also why we use diffsMockData[1] for the "first" version

    let expectedFirstVersion;
    let expectedBaseVersion;
    let expectedHeadVersion;
    const originalLocation = window.location;

    const setupTest = (includeDiffHeadParam) => {
      const diffHeadParam = includeDiffHeadParam ? '?diff_head=true' : '';

      Object.defineProperty(window, 'location', {
        writable: true,
        value: { search: diffHeadParam },
      });

      expectedFirstVersion = {
        ...diffsMockData[1],
        href: expect.any(String),
        versionName: expect.any(String),
        selected: false,
      };

      expectedBaseVersion = {
        versionName: 'baseVersion',
        version_index: DIFF_COMPARE_BASE_VERSION_INDEX,
        href: 'basePath',
        isBase: true,
        selected: false,
      };

      expectedHeadVersion = {
        versionName: 'baseVersion',
        version_index: DIFF_COMPARE_HEAD_VERSION_INDEX,
        href: 'headPath',
        isHead: true,
        selected: false,
      };
    };

    const assertVersions = (targetVersions) => {
      // base and head should be the last two versions in that order
      const targetBaseVersion = targetVersions[targetVersions.length - 2];
      const targetHeadVersion = targetVersions[targetVersions.length - 1];
      expect(targetVersions[0]).toEqual(expectedFirstVersion);
      expect(targetBaseVersion).toEqual(expectedBaseVersion);
      expect(targetHeadVersion).toEqual(expectedHeadVersion);
    };

    afterEach(() => {
      window.location = originalLocation;
    });

    it('base version selected', () => {
      setupTest();
      expectedBaseVersion.selected = true;

      const targetVersions = getters.diffCompareDropdownTargetVersions(localState, getters);
      assertVersions(targetVersions);
    });

    it('head version selected', () => {
      setupTest(true);

      expectedHeadVersion.selected = true;

      const targetVersions = getters.diffCompareDropdownTargetVersions(localState, getters);
      assertVersions(targetVersions);
    });

    it('first version selected', () => {
      // NOTE: It should not be possible to have both "diff_head=true" and
      // have anything other than the head version selected, but the user could
      // manually add "?diff_head=true" to the url. In this instance we still
      // want the actual selected version to display as "selected"
      // Passing in "true" here asserts that first version is still selected
      // even if "diff_head" is present in the url
      setupTest(true);

      expectedFirstVersion.selected = true;
      localState.startVersion = expectedFirstVersion;

      const targetVersions = getters.diffCompareDropdownTargetVersions(localState, {
        selectedTargetIndex: expectedFirstVersion.version_index,
      });
      assertVersions(targetVersions);
    });
  });

  it('diffCompareDropdownSourceVersions', () => {
    const firstDiff = localState.mergeRequestDiffs[0];
    const expectedShape = {
      ...firstDiff,
      href: firstDiff.version_path,
      commitsText: `${firstDiff.commits_count} commits,`,
      isLatestVersion: true,
      versionName: 'latest version',
      selected: true,
    };

    const sourceVersions = getters.diffCompareDropdownSourceVersions(localState, {
      selectedSourceIndex: expectedShape.version_index,
    });
    expect(sourceVersions[0]).toEqual(expectedShape);
    expect(sourceVersions[1]).toMatchObject({
      selected: false,
      isLatestVersion: false,
    });
  });
});
