import { __, n__, sprintf } from '~/locale';
import { DIFF_COMPARE_BASE_VERSION_INDEX } from '../constants';

export const selectedTargetIndex = state =>
  state.startVersion?.version_index || DIFF_COMPARE_BASE_VERSION_INDEX;

export const selectedSourceIndex = state => state.mergeRequestDiff.version_index;

export const diffCompareDropdownTargetVersions = (state, getters) => {
  // startVersion only exists if the user has selected a version other
  // than "base" so if startVersion is null then base must be selected
  const baseVersion = {
    versionName: state.targetBranchName,
    version_index: DIFF_COMPARE_BASE_VERSION_INDEX,
    href: state.mergeRequestDiff.base_version_path,
    isBase: true,
    selected: !state.startVersion,
  };
  // Appended properties here are to make the compare_dropdown_layout easier to reason about
  const formatVersion = v => {
    return {
      href: v.compare_path,
      versionName: sprintf(__(`version %{versionIndex}`), { versionIndex: v.version_index }),
      selected: v.version_index === getters.selectedTargetIndex,
      ...v,
    };
  };
  return [...state.mergeRequestDiffs.slice(1).map(formatVersion), baseVersion];
};

export const diffCompareDropdownSourceVersions = (state, getters) => {
  // Appended properties here are to make the compare_dropdown_layout easier to reason about
  return state.mergeRequestDiffs.map((v, i) => ({
    ...v,
    href: v.version_path,
    commitsText: n__(`%d commit,`, `%d commits,`, v.commits_count),
    versionName:
      i === 0
        ? __('latest version')
        : sprintf(__(`version %{versionIndex}`), { versionIndex: v.version_index }),
    selected: v.version_index === getters.selectedSourceIndex,
  }));
};
