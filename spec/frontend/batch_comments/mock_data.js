import { TEST_HOST } from 'spec/test_constants';

export const createDraft = () => ({
  author: {
    id: 1,
    name: 'Test',
    username: 'test',
    state: 'active',
    avatar_url: TEST_HOST,
  },
  current_user: { can_edit: true, can_award_emoji: false, can_resolve: false },
  discussion_id: null,
  file_hash: null,
  file_path: null,
  id: 1,
  line_code: null,
  merge_request_id: 1,
  note: 'a',
  note_html: '<p>Test</p>',
  noteable_type: 'MergeRequest',
  references: { users: [], commands: '' },
  resolve_discussion: false,
  isDraft: true,
  position: null,
});
