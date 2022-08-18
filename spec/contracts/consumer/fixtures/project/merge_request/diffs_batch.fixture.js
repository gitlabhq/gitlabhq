import { Matchers } from '@pact-foundation/pact';

const body = {
  diff_files: Matchers.eachLike({
    content_sha: Matchers.string('b0c94059db75b2473d616d4b1fde1a77533355a3'),
    submodule: Matchers.boolean(false),
    edit_path: Matchers.string('/gitlab-qa-bot/...'),
    ide_edit_path: Matchers.string('/gitlab-qa-bot/...'),
    old_path_html: Matchers.string('Gemfile'),
    new_path_html: Matchers.string('Gemfile'),
    blob: {
      id: Matchers.string('855071bb3928d140764885964f7be1bb3e582495'),
      path: Matchers.string('Gemfile'),
      name: Matchers.string('Gemfile'),
      mode: Matchers.string('1234567'),
      readable_text: Matchers.boolean(true),
      icon: Matchers.string('doc-text'),
    },
    can_modify_blob: Matchers.boolean(false),
    file_identifier_hash: Matchers.string('67d82b8716a5b6c52c7abf0b2cd99c7594ed3587'),
    file_hash: Matchers.string('67d82b8716a5b6c52c7abf0b2cd99c7594ed3587'),
    file_path: Matchers.string('Gemfile'),
    old_path: Matchers.string('Gemfile'),
    new_path: Matchers.string('Gemfile'),
    new_file: Matchers.boolean(false),
    renamed_file: Matchers.boolean(false),
    deleted_file: Matchers.boolean(false),
    diff_refs: {
      base_sha: Matchers.string('67d82b8716a5b6c52c7abf0b2cd99c7594ed3587'),
      start_sha: Matchers.string('67d82b8716a5b6c52c7abf0b2cd99c7594ed3587'),
      head_sha: Matchers.string('67d82b8716a5b6c52c7abf0b2cd99c7594ed3587'),
    },
    mode_changed: Matchers.boolean(false),
    a_mode: Matchers.string('123456'),
    b_mode: Matchers.string('123456'),
    viewer: {
      name: Matchers.string('text'),
      collapsed: Matchers.boolean(false),
    },
    old_size: Matchers.integer(2288),
    new_size: Matchers.integer(2288),
    added_lines: Matchers.integer(1),
    removed_lines: Matchers.integer(1),
    load_collapsed_diff_url: Matchers.string('/gitlab-qa-bot/...'),
    view_path: Matchers.string('/gitlab-qa-bot/...'),
    context_lines_path: Matchers.string('/gitlab-qa-bot/...'),
    highlighted_diff_lines: Matchers.eachLike({
      // The following values can also be null which is not supported
      // line_code: Matchers.string('de3150c01c3a946a6168173c4116741379fe3579_1_1'),
      // old_line: Matchers.integer(1),
      // new_line: Matchers.integer(1),
      text: Matchers.string('source'),
      rich_text: Matchers.string('<span></span>'),
      can_receive_suggestion: Matchers.boolean(true),
    }),
    is_fully_expanded: Matchers.boolean(false),
  }),
  pagination: {
    total_pages: Matchers.integer(1),
  },
};

const DiffsBatch = {
  body: Matchers.extractPayload(body),

  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a merge request with diffs exists',
    uponReceiving: 'a request for diff lines',
  },

  request: {
    withRequest: {
      method: 'GET',
      path: '/gitlab-org/gitlab-qa/-/merge_requests/1/diffs_batch.json',
      headers: {
        Accept: '*/*',
      },
      query: 'page=0',
    },
  },
};

export { DiffsBatch };
