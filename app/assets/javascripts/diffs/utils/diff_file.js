import { diffViewerModes as viewerModes } from '~/ide/constants';
import { changeInPercent, numberToHumanSize } from '~/lib/utils/number_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { uuids } from '~/lib/utils/uuids';

import {
  DIFF_FILE_SYMLINK_MODE,
  DIFF_FILE_DELETED_MODE,
  DIFF_FILE_MANUAL_COLLAPSE,
  DIFF_FILE_AUTOMATIC_COLLAPSE,
} from '../constants';
import { getDerivedMergeRequestInformation } from './merge_request';

function fileSymlinkInformation(file, fileList) {
  const duplicates = fileList.filter((iteratedFile) => iteratedFile.file_hash === file.file_hash);
  const includesSymlink = duplicates.some((iteratedFile) => {
    return [iteratedFile.a_mode, iteratedFile.b_mode].includes(DIFF_FILE_SYMLINK_MODE);
  });
  const brokenSymlinkScenario = duplicates.length > 1 && includesSymlink;

  return (
    brokenSymlinkScenario && {
      replaced: file.b_mode === DIFF_FILE_DELETED_MODE,
      wasSymbolic: file.a_mode === DIFF_FILE_SYMLINK_MODE,
      isSymbolic: file.b_mode === DIFF_FILE_SYMLINK_MODE,
      wasReal: ![DIFF_FILE_SYMLINK_MODE, DIFF_FILE_DELETED_MODE].includes(file.a_mode),
      isReal: ![DIFF_FILE_SYMLINK_MODE, DIFF_FILE_DELETED_MODE].includes(file.b_mode),
    }
  );
}

function collapsed(file) {
  const viewer = file.viewer || {};

  return {
    automaticallyCollapsed: viewer.automaticallyCollapsed || viewer.collapsed || false,
    manuallyCollapsed: null,
  };
}

function identifier(file) {
  const { userOrGroup, project, id } = getDerivedMergeRequestInformation({
    endpoint: file.load_collapsed_diff_url,
  });

  return uuids({
    seeds: [userOrGroup, project, id, file.file_identifier_hash, file.blob?.id],
  })[0];
}

export const isNotDiffable = (file) => file?.viewer?.name === viewerModes.not_diffable;

export function prepareRawDiffFile({ file, allFiles, meta = false }) {
  const additionalProperties = {
    brokenSymlink: fileSymlinkInformation(file, allFiles),
    viewer: {
      ...file.viewer,
      ...collapsed(file),
    },
  };

  // It's possible, but not confirmed, that `blob.id` isn't available sometimes
  // See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49506#note_464692057
  // We don't want duplicate IDs if that's the case, so we just don't assign an ID
  if (!meta && file.blob?.id && file.load_collapsed_diff_url) {
    additionalProperties.id = identifier(file);
  }

  return Object.assign(file, additionalProperties);
}

export function collapsedType(file) {
  const isManual = typeof file.viewer?.manuallyCollapsed === 'boolean';

  return isManual ? DIFF_FILE_MANUAL_COLLAPSE : DIFF_FILE_AUTOMATIC_COLLAPSE;
}

export function isCollapsed(file) {
  const type = collapsedType(file);
  const collapsedStates = {
    [DIFF_FILE_AUTOMATIC_COLLAPSE]: file.viewer?.automaticallyCollapsed || false,
    [DIFF_FILE_MANUAL_COLLAPSE]: file.viewer?.manuallyCollapsed,
  };

  return collapsedStates[type];
}

export function getShortShaFromFile(file) {
  return file.content_sha ? truncateSha(String(file.content_sha)) : null;
}

export function stats(file) {
  let valid = false;
  let classes = '';
  let sign = '';
  let text = '';
  let percent = 0;
  let diff = 0;

  if (file) {
    percent = changeInPercent(file.old_size, file.new_size);
    diff = file.new_size - file.old_size;
    sign = diff >= 0 ? '+' : '';
    text = `${sign}${numberToHumanSize(diff)} (${sign}${percent}%)`;
    valid = true;

    if (diff > 0) {
      classes = 'gl-text-green-600';
    } else if (diff < 0) {
      classes = 'gl-text-red-500';
    }
  }

  return {
    changed: diff,
    text,
    percent,
    classes,
    sign,
    valid,
  };
}
