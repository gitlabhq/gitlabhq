import {
  DIFF_NOTE_TYPE,
  TEXT_DIFF_POSITION_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
} from '~/diffs/constants';

export function toLineType(lineChange) {
  if (!lineChange) return undefined;
  const { change, position } = lineChange;
  if (change === 'added') return NEW_LINE_TYPE;
  if (change === 'removed') return OLD_LINE_TYPE;
  return position === 'new' ? NEW_LINE_TYPE : OLD_LINE_TYPE;
}

export function buildReplyData({ discussion, noteText, noteableData, diffRefs }) {
  return {
    endpoint: noteableData.create_note_path,
    data: {
      in_reply_to_discussion_id: discussion.reply_id,
      target_type: noteableData.targetType,
      note: { note: noteText },
      merge_request_diff_head_sha: diffRefs.head_sha,
    },
  };
}

export function buildUpdateNoteData({ note, noteText, noteableData }) {
  return {
    endpoint: note.path,
    note: {
      target_type: noteableData.targetType,
      target_id: note.noteable_id,
      note: { note: noteText },
    },
  };
}

export function buildLineDiscussionData({ noteData, noteableData, viewConfig, diffRefs }) {
  const { position, lineChange, lineCode, note } = noteData;
  return {
    endpoint: noteableData.create_note_path,
    data: {
      view: viewConfig.viewType,
      line_type: toLineType(lineChange),
      merge_request_diff_head_sha: diffRefs.head_sha,
      note_project_id: '',
      target_type: noteableData.targetType,
      target_id: noteableData.id,
      return_discussion: true,
      note: {
        note,
        position: JSON.stringify({
          base_sha: diffRefs.base_sha,
          start_sha: diffRefs.start_sha,
          head_sha: diffRefs.head_sha,
          ...position,
          position_type: position.position_type || TEXT_DIFF_POSITION_TYPE,
          line_range: null,
          ignore_whitespace_change: !viewConfig.showWhitespace,
        }),
        noteable_type: noteableData.noteableType,
        noteable_id: noteableData.id,
        commit_id: null,
        type: DIFF_NOTE_TYPE,
        line_code: lineCode || null,
      },
    },
  };
}
