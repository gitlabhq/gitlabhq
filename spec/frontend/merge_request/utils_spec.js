import {
  toLineType,
  buildReplyData,
  buildUpdateNoteData,
  buildLineDiscussionData,
  buildDraftLineDiscussionData,
  buildDraftReplyData,
} from '~/merge_request/utils';

describe('Merge request utils', () => {
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

    it('builds the correct payload', () => {
      const result = buildReplyData({
        discussion: { reply_id: 'reply-1' },
        noteText: 'reply text',
        noteableData,
        sourceHeadSha: 'source999',
      });

      expect(result).toEqual({
        endpoint: '/api/notes',
        data: {
          in_reply_to_discussion_id: 'reply-1',
          target_type: 'merge_request',
          note: { note: 'reply text' },
          merge_request_diff_head_sha: 'source999',
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

    const discussion = {
      position: {
        old_path: 'a.rb',
        new_path: 'a.rb',
        old_line: null,
        new_line: 5,
        base_sha: 'base000',
        start_sha: 'start111',
        head_sha: 'head222',
      },
      lineChange: { change: 'added', position: 'new' },
      lineCode: 'abc_0_5',
    };

    it('builds the correct payload', () => {
      const result = buildLineDiscussionData({
        discussion,
        noteBody: 'test comment',
        noteableData,
        viewConfig,
        sourceHeadSha: 'source999',
      });

      expect(result).toEqual({
        endpoint: '/api/notes',
        data: {
          view: 'inline',
          line_type: 'new',
          merge_request_diff_head_sha: 'source999',
          note_project_id: '',
          target_type: 'merge_request',
          target_id: 42,
          return_discussion: true,
          note: {
            note: 'test comment',
            position: JSON.stringify({
              ...discussion.position,
              position_type: 'text',
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

    it('passes commitId from discussion when provided', () => {
      const result = buildLineDiscussionData({
        discussion: { ...discussion, commitId: 'abc123' },
        noteBody: 'test comment',
        noteableData,
        viewConfig,
        sourceHeadSha: 'source999',
      });

      expect(result.data.note.commit_id).toBe('abc123');
    });

    it('builds the position refs from the discussion position', () => {
      const result = buildLineDiscussionData({
        discussion,
        noteBody: 'test comment',
        noteableData,
        viewConfig,
        sourceHeadSha: 'source999',
      });
      const position = JSON.parse(result.data.note.position);
      expect(position.base_sha).toBe('base000');
      expect(position.start_sha).toBe('start111');
      expect(position.head_sha).toBe('head222');
    });

    it('sets ignore_whitespace_change to true when whitespace is hidden', () => {
      const result = buildLineDiscussionData({
        discussion,
        noteBody: 'test comment',
        noteableData,
        viewConfig: { ...viewConfig, showWhitespace: false },
        sourceHeadSha: 'source999',
      });
      const position = JSON.parse(result.data.note.position);
      expect(position.ignore_whitespace_change).toBe(true);
    });

    it('forces ignore_whitespace_change to false when showWhitespace override is true', () => {
      const result = buildLineDiscussionData({
        discussion,
        noteBody: 'test comment',
        noteableData,
        viewConfig: { ...viewConfig, showWhitespace: false },
        sourceHeadSha: 'source999',
        showWhitespace: true,
      });
      const position = JSON.parse(result.data.note.position);
      expect(position.ignore_whitespace_change).toBe(false);
    });
  });

  describe('buildDraftLineDiscussionData', () => {
    const viewConfig = { viewType: 'inline', showWhitespace: true };
    const discussion = {
      position: {
        old_path: 'a.rb',
        new_path: 'a.rb',
        old_line: null,
        new_line: 5,
        base_sha: 'base000',
        start_sha: 'start111',
        head_sha: 'head222',
      },
      lineCode: 'abc_0_5',
    };

    it('builds the correct payload', () => {
      const result = buildDraftLineDiscussionData({
        discussion,
        noteBody: 'draft comment',
        viewConfig,
      });

      expect(result).toEqual({
        note: {
          note: 'draft comment',
          position: JSON.stringify({
            ...discussion.position,
            position_type: 'text',
            ignore_whitespace_change: false,
          }),
          type: 'DiffNote',
          line_code: 'abc_0_5',
        },
      });
    });

    it('sets ignore_whitespace_change to true when whitespace is hidden', () => {
      const result = buildDraftLineDiscussionData({
        discussion,
        noteBody: 'draft comment',
        viewConfig: { ...viewConfig, showWhitespace: false },
      });
      const position = JSON.parse(result.note.position);
      expect(position.ignore_whitespace_change).toBe(true);
    });

    it('forces ignore_whitespace_change to false when showWhitespace override is true', () => {
      const result = buildDraftLineDiscussionData({
        discussion,
        noteBody: 'draft comment',
        viewConfig: { ...viewConfig, showWhitespace: false },
        showWhitespace: true,
      });
      const position = JSON.parse(result.note.position);
      expect(position.ignore_whitespace_change).toBe(false);
    });

    it('uses explicit position_type when provided', () => {
      const result = buildDraftLineDiscussionData({
        discussion: {
          ...discussion,
          position: { ...discussion.position, position_type: 'image' },
        },
        noteBody: 'draft comment',
        viewConfig,
      });
      const position = JSON.parse(result.note.position);
      expect(position.position_type).toBe('image');
    });

    it('sets line_code to null when not provided', () => {
      const result = buildDraftLineDiscussionData({
        discussion: { position: discussion.position },
        noteBody: 'draft comment',
        viewConfig,
      });
      expect(result.note.line_code).toBeNull();
    });

    it('builds the position refs from the discussion position', () => {
      const result = buildDraftLineDiscussionData({
        discussion,
        noteBody: 'draft comment',
        viewConfig,
      });
      const position = JSON.parse(result.note.position);
      expect(position.base_sha).toBe('base000');
      expect(position.start_sha).toBe('start111');
      expect(position.head_sha).toBe('head222');
    });
  });

  describe('buildDraftReplyData', () => {
    it.each`
      resolveDiscussion | expectedResolve
      ${undefined}      | ${false}
      ${true}           | ${true}
    `(
      'sets resolve_discussion=$expectedResolve when resolveDiscussion=$resolveDiscussion',
      ({ resolveDiscussion, expectedResolve }) => {
        const result = buildDraftReplyData({
          discussion: { reply_id: 'reply-1' },
          noteText: 'draft reply',
          sourceHeadSha: 'source999',
          resolveDiscussion,
        });

        expect(result).toEqual({
          in_reply_to_discussion_id: 'reply-1',
          draft_note: { note: 'draft reply', resolve_discussion: expectedResolve },
          merge_request_diff_head_sha: 'source999',
        });
      },
    );
  });
});
