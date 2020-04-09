import * as getters from '~/diffs/store/getters';
import state from '~/diffs/store/modules/diff_state';
import { DIFF_COMPARE_BASE_VERSION_INDEX } from '~/diffs/constants';
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
    // and appends a "base" version which is why we use diffsMockData[1] below
    // This is to display "base" at the end of the target dropdown
    const expectedFirstVersion = {
      ...diffsMockData[1],
      href: expect.any(String),
      versionName: expect.any(String),
    };

    const expectedBaseVersion = {
      versionName: 'baseVersion',
      version_index: DIFF_COMPARE_BASE_VERSION_INDEX,
      href: 'basePath',
      isBase: true,
    };

    it('base version selected', () => {
      expectedFirstVersion.selected = false;
      expectedBaseVersion.selected = true;

      const targetVersions = getters.diffCompareDropdownTargetVersions(localState, {
        selectedTargetIndex: DIFF_COMPARE_BASE_VERSION_INDEX,
      });

      const lastVersion = targetVersions[targetVersions.length - 1];
      expect(targetVersions[0]).toEqual(expectedFirstVersion);
      expect(lastVersion).toEqual(expectedBaseVersion);
    });

    it('first version selected', () => {
      expectedFirstVersion.selected = true;
      expectedBaseVersion.selected = false;

      localState.startVersion = expectedFirstVersion;

      const targetVersions = getters.diffCompareDropdownTargetVersions(localState, {
        selectedTargetIndex: expectedFirstVersion.version_index,
      });

      const lastVersion = targetVersions[targetVersions.length - 1];
      expect(targetVersions[0]).toEqual(expectedFirstVersion);
      expect(lastVersion).toEqual(expectedBaseVersion);
    });
  });

  it('diffCompareDropdownSourceVersions', () => {
    const firstDiff = localState.mergeRequestDiffs[0];
    const expectedShape = {
      ...firstDiff,
      href: firstDiff.version_path,
      commitsText: `${firstDiff.commits_count} commits,`,
      versionName: 'latest version',
      selected: true,
    };

    const sourceVersions = getters.diffCompareDropdownSourceVersions(localState, {
      selectedSourceIndex: expectedShape.version_index,
    });
    expect(sourceVersions[0]).toEqual(expectedShape);
    expect(sourceVersions[1].selected).toBe(false);
  });
});
