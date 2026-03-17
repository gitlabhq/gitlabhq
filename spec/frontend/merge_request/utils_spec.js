import {
  toLineType,
  buildReplyData,
  buildUpdateNoteData,
  buildLineDiscussionData,
} from '~/merge_request/utils';

describe('toLineType', () => {
  it('returns undefined when lineChange is falsy', () => {
    expect(toLineType(undefined)).toBeUndefined();
    expect(toLineType(null)).toBeUndefined();
  });

  it('returns "new" for added change', () => {
    expect(toLineType({ change: 'added', position: 'old' })).toBe('new');
  });

  it('returns "old" for removed change', () => {
    expect(toLineType({ change: 'removed', position: 'new' })).toBe('old');
  });

  it('falls back to position when no change type', () => {
    expect(toLineType({ change: undefined, position: 'new' })).toBe('new');
    expect(toLineType({ change: undefined, position: 'old' })).toBe('old');
  });
});

describe('buildReplyData', () => {
  const noteableData = {
    create_note_path: '/api/notes',
    targetType: 'merge_request',
  };

  const diffRefs = { head_sha: 'head222' };

  it('builds the correct payload', () => {
    const result = buildReplyData({
      discussion: { reply_id: 'reply-1' },
      noteText: 'reply text',
      noteableData,
      diffRefs,
    });

    expect(result).toEqual({
      endpoint: '/api/notes',
      data: {
        in_reply_to_discussion_id: 'reply-1',
        target_type: 'merge_request',
        note: { note: 'reply text' },
        merge_request_diff_head_sha: 'head222',
      },
    });
  });
});

describe('buildUpdateNoteData', () => {
  const noteableData = { targetType: 'merge_request' };

  it('builds the correct payload', () => {
    const result = buildUpdateNoteData({
      note: { path: '/note/1', noteable_id: 10 },
      noteText: 'updated',
      noteableData,
    });

    expect(result).toEqual({
      endpoint: '/note/1',
      note: {
        target_type: 'merge_request',
        target_id: 10,
        note: { note: 'updated' },
      },
    });
  });
});

describe('buildLineDiscussionData', () => {
  const noteableData = {
    create_note_path: '/api/notes',
    targetType: 'merge_request',
    id: 42,
    noteableType: 'MergeRequest',
  };

  const viewConfig = {
    viewType: 'inline',
    showWhitespace: true,
  };

  const diffRefs = {
    base_sha: 'base000',
    start_sha: 'start111',
    head_sha: 'head222',
  };

  const noteData = {
    position: { old_path: 'a.rb', new_path: 'a.rb', old_line: null, new_line: 5 },
    lineChange: { change: 'added', position: 'new' },
    lineCode: 'abc_0_5',
    note: 'test comment',
  };

  it('builds the correct payload', () => {
    const result = buildLineDiscussionData({ noteData, noteableData, viewConfig, diffRefs });

    expect(result).toEqual({
      endpoint: '/api/notes',
      data: {
        view: 'inline',
        line_type: 'new',
        merge_request_diff_head_sha: 'head222',
        note_project_id: '',
        target_type: 'merge_request',
        target_id: 42,
        return_discussion: true,
        note: {
          note: 'test comment',
          position: JSON.stringify({
            base_sha: 'base000',
            start_sha: 'start111',
            head_sha: 'head222',
            old_path: 'a.rb',
            new_path: 'a.rb',
            old_line: null,
            new_line: 5,
            position_type: 'text',
            line_range: null,
            ignore_whitespace_change: false,
          }),
          noteable_type: 'MergeRequest',
          noteable_id: 42,
          commit_id: null,
          type: 'DiffNote',
          line_code: 'abc_0_5',
        },
      },
    });
  });

  it('sets ignore_whitespace_change to true when whitespace is hidden', () => {
    const result = buildLineDiscussionData({
      noteData,
      noteableData,
      viewConfig: { ...viewConfig, showWhitespace: false },
      diffRefs,
    });
    const position = JSON.parse(result.data.note.position);
    expect(position.ignore_whitespace_change).toBe(true);
  });
});
