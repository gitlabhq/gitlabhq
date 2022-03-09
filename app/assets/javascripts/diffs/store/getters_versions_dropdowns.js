import { parseBoolean } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __, n__, sprintf } from '~/locale';
import { DIFF_COMPARE_BASE_VERSION_INDEX, DIFF_COMPARE_HEAD_VERSION_INDEX } from '../constants';

export const selectedTargetIndex = (state) =>
  state.startVersion?.version_index || DIFF_COMPARE_BASE_VERSION_INDEX;

export const selectedSourceIndex = (state) => state.mergeRequestDiff.version_index;

export const selectedContextCommitsDiffs = (state) =>
  state.contextCommitsDiff && state.contextCommitsDiff.showing_context_commits_diff;

export const diffCompareDropdownTargetVersions = (state, getters) => {
  // startVersion only exists if the user has selected a version other
  // than "base" so if startVersion is null then base must be selected

  const diffHeadParam = getParameterByName('diff_head');
  const diffHead = parseBoolean(diffHeadParam) || !diffHeadParam;
  const isBaseSelected = !state.startVersion;
  const isHeadSelected = !state.startVersion && diffHead;
  let baseVersion = null;

  if (!state.mergeRequestDiff.head_version_path) {
    baseVersion = {
      versionName: state.targetBranchName,
      version_index: DIFF_COMPARE_BASE_VERSION_INDEX,
      href: state.mergeRequestDiff.base_version_path,
      isBase: true,
      selected: isBaseSelected,
    };
  }

  const headVersion = {
    versionName: state.targetBranchName,
    version_index: DIFF_COMPARE_HEAD_VERSION_INDEX,
    href: state.mergeRequestDiff.head_version_path,
    isHead: true,
    selected: isHeadSelected,
  };
  // Appended properties here are to make the compare_dropdown_layout easier to reason about
  const formatVersion = (v) => {
    return {
      href: v.compare_path,
      versionName: sprintf(__(`version %{versionIndex}`), { versionIndex: v.version_index }),
      selected: v.version_index === getters.selectedTargetIndex,
      ...v,
    };
  };

  return [
    ...state.mergeRequestDiffs.slice(1).map(formatVersion),
    baseVersion,
    state.mergeRequestDiff.head_version_path && headVersion,
  ].filter((a) => a);
};

export const diffCompareDropdownSourceVersions = (state, getters) => {
  // Appended properties here are to make the compare_dropdown_layout easier to reason about
  const versions = state.mergeRequestDiffs.map((v, i) => {
    const isLatestVersion = i === 0;

    return {
      ...v,
      href: v.version_path,
      commitsText: n__(`%d commit,`, `%d commits,`, v.commits_count),
      isLatestVersion,
      versionName: isLatestVersion
        ? __('latest version')
        : sprintf(__(`version %{versionIndex}`), { versionIndex: v.version_index }),
      selected:
        v.version_index === getters.selectedSourceIndex && !getters.selectedContextCommitsDiffs,
    };
  });

  const { contextCommitsDiff } = state;
  if (contextCommitsDiff) {
    versions.push({
      href: contextCommitsDiff.diffs_path,
      commitsText: n__(`%d commit`, `%d commits`, contextCommitsDiff.commits_count),
      versionName: __('previously merged commits'),
      selected: getters.selectedContextCommitsDiffs,
      addDivider: state.mergeRequestDiffs.length > 0,
    });
  }
  return versions;
};
