import { Matchers } from '@pact-foundation/pact';

const body = {
  real_size: Matchers.string('1'),
  size: Matchers.integer(1),
  branch_name: Matchers.string('testing-branch-1'),
  source_branch_exists: Matchers.boolean(true),
  target_branch_name: Matchers.string('master'),
  merge_request_diff: {
    created_at: Matchers.iso8601DateTimeWithMillis('2022-02-17T11:47:08.804Z'),
    commits_count: Matchers.integer(1),
    latest: Matchers.boolean(true),
    short_commit_sha: Matchers.string('aee1ffec'),
    base_version_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_id=10581773',
    ),
    head_version_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_head=true',
    ),
    version_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_id=10581773',
    ),
    compare_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_id=10581773&start_sha=aee1ffec2299c0cfb17c8821e931339b73a3759f',
    ),
  },
  latest_diff: Matchers.boolean(true),
  latest_version_path: Matchers.string('/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs'),
  added_lines: Matchers.integer(1),
  removed_lines: Matchers.integer(1),
  render_overflow_warning: Matchers.boolean(false),
  email_patch_path: Matchers.string('/gitlab-qa-bot/contract-testing/-/merge_requests/1.patch'),
  plain_diff_path: Matchers.string('/gitlab-qa-bot/contract-testing/-/merge_requests/1.diff'),
  merge_request_diffs: Matchers.eachLike({
    commits_count: Matchers.integer(1),
    latest: Matchers.boolean(true),
    short_commit_sha: Matchers.string('aee1ffec'),
    base_version_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_id=10581773',
    ),
    head_version_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_head=true',
    ),
    version_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_id=10581773',
    ),
    compare_path: Matchers.string(
      '/gitlab-qa-bot/contract-testing/-/merge_requests/1/diffs?diff_id=10581773&start_sha=aee1ffec2299c0cfb17c8821e931339b73a3759f',
    ),
  }),
  definition_path_prefix: Matchers.string(
    '/gitlab-qa-bot/contract-testing/-/blob/aee1ffec2299c0cfb17c8821e931339b73a3759f',
  ),
  diff_files: Matchers.eachLike({
    added_lines: Matchers.integer(1),
    removed_lines: Matchers.integer(1),
    new_path: Matchers.string('Gemfile'),
    old_path: Matchers.string('Gemfile'),
    new_file: Matchers.boolean(false),
    deleted_file: Matchers.boolean(false),
    submodule: Matchers.boolean(false),
    file_identifier_hash: Matchers.string('67d82b8716a5b6c52c7abf0b2cd99c7594ed3587'),
    file_hash: Matchers.string('de3150c01c3a946a6168173c4116741379fe3579'),
  }),
  has_conflicts: Matchers.boolean(false),
  can_merge: Matchers.boolean(false),
  project_path: Matchers.string('gitlab-qa-bot/contract-testing'),
  project_name: Matchers.string('contract-testing'),
};

const DiffsMetadata = {
  body: Matchers.extractPayload(body),

  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a merge request exists',
    uponReceiving: 'a request for diffs metadata',
  },

  request: {
    withRequest: {
      method: 'GET',
      path: '/gitlab-org/gitlab-qa/-/merge_requests/1/diffs_metadata.json',
      headers: {
        Accept: '*/*',
      },
    },
  },
};

export { DiffsMetadata };
