import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';

export const TYPE_ACTIVITY = 'activity';
export const TYPE_COMMENT = 'comment';
export const TYPE_DESIGN = 'design';
export const TYPE_SNIPPET = 'snippet';

export const BULK_IMPORT_STATIC_ITEMS = {
  badges: __('Badge'),
  boards: s__('Boards|Board'),
  epics: __('Epic'),
  issues: __('Issue'),
  labels: __('Label'),
  iterations: __('Iteration'),
  iterations_cadences: s__('Iterations|Iteration cadence'),
  members: __('Member'),
  merge_requests: __('Merge request'),
  milestones: __('Milestone'),
  namespace_settings: s__('GroupSettings|Namespace setting'),
  project: __('Project'),
  self: __('Group'),
  auto_devops: __('Auto DevOps'),
  ci_pipelines: __('CI pipeline'),
  container_expiration_policy: __('Container expiration policy'),
  design: __('Design'),
  project_feature: __('Project feature'),
  protected_branches: __('Protected Branch'),
  push_rule: __('Push rule'),
  repository: __('Repository'),
  service_desk_setting: __('Service Desk'),
  vulnerabilities: __('Vulnerabilities'),
  commit_notes: __('Commit notes'),
};

const STATISTIC_ITEMS = {
  diff_note: __('Diff notes'),
  issue: __('Issues'),
  issue_attachment: s__('GithubImporter|Issue attachments'),
  issue_event: __('Issue events'),
  label: __('Labels'),
  lfs_object: __('LFS objects'),
  merge_request_attachment: s__('GithubImporter|PR attachments'),
  milestone: __('Milestones'),
  note: __('Notes'),
  note_attachment: s__('GithubImporter|Note attachments'),
  protected_branch: __('Protected branches'),
  collaborator: s__('GithubImporter|Collaborators'),
  pull_request: s__('GithubImporter|Pull requests'),
  pull_request_merged_by: s__('GithubImporter|PR mergers'),
  pull_request_review: s__('GithubImporter|PR reviews'),
  pull_request_review_request: s__('GithubImporter|PR reviewers'),
  release: __('Releases'),
  release_attachment: s__('GithubImporter|Release attachments'),
};

// support both camel case and snake case versions
Object.assign(STATISTIC_ITEMS, convertObjectPropsToCamelCase(STATISTIC_ITEMS));

export { STATISTIC_ITEMS };
