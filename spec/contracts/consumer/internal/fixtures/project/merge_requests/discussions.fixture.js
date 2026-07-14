import { Matchers } from '@pact-foundation/pact';

const body = Matchers.eachLike({
  id: Matchers.string('fd73763cbcbf7b29eb8765d969a38f7d735e222a'),
  reply_id: Matchers.string('fd73763cbcbf7b29eb8765d969a38f7d735e222a'),
  project_id: Matchers.integer(6954442),
  confidential: Matchers.boolean(false),
  diff_discussion: Matchers.boolean(false),
  expanded: Matchers.boolean(false),
  for_commit: Matchers.boolean(false),
  individual_note: Matchers.boolean(true),
  resolvable: Matchers.boolean(false),
  resolved_by_push: Matchers.boolean(false),
  notes: Matchers.eachLike({
    id: Matchers.string('76489845'),
    author: {
      id: Matchers.integer(1675733),
      username: Matchers.string('gitlab-qa-bot'),
      name: Matchers.string('gitlab-qa-bot'),
      state: Matchers.string('active'),
      avatar_url: Matchers.string(
        'https://secure.gravatar.com/avatar/8355ad0f2761367fae6b9c4fe80994b9?s=80&d=identicon',
      ),
      show_status: Matchers.boolean(false),
      path: Matchers.string('/gitlab-qa-bot'),
    },
    created_at: Matchers.iso8601DateTimeWithMillis('2022-02-22T07:06:55.038Z'),
    updated_at: Matchers.iso8601DateTimeWithMillis('2022-02-22T07:06:55.038Z'),
    system: Matchers.boolean(false),
    noteable_id: Matchers.integer(8333422),
    noteable_type: Matchers.string('MergeRequest'),
    resolvable: Matchers.boolean(false),
    resolved: Matchers.boolean(true),
    confidential: Matchers.boolean(false),
    noteable_iid: Matchers.integer(1),
    note: Matchers.string('This is a test comment'),
    note_html: Matchers.string(
      '<p data-sourcepos="1:1-1:22" dir="auto">This is a test comment</p>',
    ),
    current_user: {
      can_edit: Matchers.boolean(true),
      can_award_emoji: Matchers.boolean(true),
      can_resolve: Matchers.boolean(false),
      can_resolve_discussion: Matchers.boolean(false),
    },
    is_noteable_author: Matchers.boolean(true),
    discussion_id: Matchers.string('fd73763cbcbf7b29eb8765d969a38f7d735e222a'),
    emoji_awardable: Matchers.boolean(true),
    report_abuse_path: Matchers.string('/gitlab-qa-bot/...'),
    noteable_note_url: Matchers.string('https://staging.gitlab.com/gitlab-qa-bot/...'),
    cached_markdown_version: Matchers.integer(1900552),
    human_access: Matchers.string('Maintainer'),
    is_contributor: Matchers.boolean(false),
    project_name: Matchers.string('contract-testing'),
    path: Matchers.string('/gitlab-qa-bot/...'),
  }),
  resolved: Matchers.boolean(true),
});

const Discussions = {
  body: Matchers.extractPayload(body),

  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a merge request with discussions exists',
    uponReceiving: 'a request for discussions',
  },

  request: {
    withRequest: {
      method: 'GET',
      path: '/gitlab-org/gitlab-qa/-/merge_requests/1/discussions.json',
      headers: {
        Accept: '*/*',
      },
    },
  },
};

export { Discussions };
