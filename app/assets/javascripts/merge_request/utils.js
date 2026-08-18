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

export function buildReplyData({ discussion, noteText, noteableData, sourceHeadSha }) {
  return {
    endpoint: noteableData.create_note_path,
    data: {
      in_reply_to_discussion_id: discussion.reply_id,
      target_type: noteableData.targetType,
      note: { note: noteText },
      merge_request_diff_head_sha: sourceHeadSha,
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

export function buildLineDiscussionData({
  discussion,
  noteBody,
  noteableData,
  viewConfig,
  sourceHeadSha,
  showWhitespace,
}) {
  const { position, lineChange, lineCode, commitId } = discussion;
  return {
    endpoint: noteableData.create_note_path,
    data: {
      view: viewConfig.viewType,
      line_type: toLineType(lineChange),
      merge_request_diff_head_sha: sourceHeadSha,
      note_project_id: '',
      target_type: noteableData.targetType,
      target_id: noteableData.id,
      return_discussion: true,
      note: {
        note: noteBody,
        position: JSON.stringify({
          ...position,
          position_type: position.position_type || TEXT_DIFF_POSITION_TYPE,
          ignore_whitespace_change: !(showWhitespace ?? viewConfig.showWhitespace),
        }),
        noteable_type: noteableData.noteableType,
        noteable_id: noteableData.id,
        commit_id: commitId || null,
        type: DIFF_NOTE_TYPE,
        line_code: lineCode || null,
      },
    },
  };
}

export function buildDraftLineDiscussionData({ discussion, noteBody, viewConfig, showWhitespace }) {
  const { position, lineCode, commitId } = discussion;
  return {
    note: {
      note: noteBody,
      position: JSON.stringify({
        ...position,
        position_type: position.position_type || TEXT_DIFF_POSITION_TYPE,
        ignore_whitespace_change: !(showWhitespace ?? viewConfig.showWhitespace),
      }),
      type: DIFF_NOTE_TYPE,
      commit_id: commitId || null,
      line_code: lineCode || null,
    },
  };
}

export function buildDraftReplyData({
  discussion,
  noteText,
  sourceHeadSha,
  resolveDiscussion = false,
}) {
  return {
    in_reply_to_discussion_id: discussion.reply_id,
    draft_note: { note: noteText, resolve_discussion: resolveDiscussion },
    merge_request_diff_head_sha: sourceHeadSha,
  };
}
