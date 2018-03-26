import _ from 'underscore';
import {
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  TEXT_DIFF_POSITION_TYPE,
  DIFF_NOTE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
} from '../constants';

export const findDiffLineIndex = options => {
  const { diffLines, lineCode, linePosition, formId } = options;

  return _.findIndex(diffLines, l => {
    const line = linePosition ? l[linePosition] : l;

    if (!line) {
      return null;
    }

    if (formId) {
      return line.id === formId;
    }

    return line.lineCode === lineCode;
  });
};

export const getReversePosition = linePosition => {
  if (linePosition === LINE_POSITION_RIGHT) {
    return LINE_POSITION_LEFT;
  }

  return LINE_POSITION_RIGHT;
};

export const getNoteFormData = params => {
  const {
    note,
    noteableType,
    noteableData,
    diffFile,
    noteTargetLine,
    diffViewType,
    linePosition,
  } = params;

  // TODO: Discuss with @felipe_arthur to remove this JSON.stringify
  const position = JSON.stringify({
    base_sha: diffFile.diffRefs.baseSha,
    start_sha: diffFile.diffRefs.startSha,
    head_sha: diffFile.diffRefs.headSha,
    old_path: diffFile.oldPath,
    new_path: diffFile.newPath,
    position_type: TEXT_DIFF_POSITION_TYPE,
    old_line: noteTargetLine.oldLine,
    new_line: noteTargetLine.newLine,
  });

  // TODO: @fatihacet - Double check empty strings
  const postData = {
    view: diffViewType,
    line_type:
      linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
    merge_request_diff_head_sha: diffFile.diffRefs.headSha,
    in_reply_to_discussion_id: '',
    note_project_id: '',
    target_type: noteableType,
    target_id: noteableData.id,
    'note[noteable_type]': noteableType,
    'note[noteable_id]': noteableData.id,
    'note[commit_id]': '',
    'note[type]': DIFF_NOTE_TYPE,
    'note[line_code]': noteTargetLine.lineCode,
    'note[note]': note,
    'note[position]': position,
  };

  return {
    endpoint: noteableData.create_note_path,
    data: postData,
  };
};
