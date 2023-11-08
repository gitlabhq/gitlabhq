import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';

export const BULK_IMPORT_STATIC_ITEMS = {
  badges: __('Badge'),
  boards: s__('IssueBoards|Board'),
  epics: __('Epic'),
  issues: __('Issue'),
  labels: __('Label'),
  members: __('Member'),
  merge_requests: __('Merge request'),
  milestones: __('Milestone'),
  project: __('Project'),
};

const STATISTIC_ITEMS = {
  diff_note: __('Diff notes'),
  issue: __('Issues'),
  issue_attachment: s__('GithubImporter|Issue links'),
  issue_event: __('Issue events'),
  label: __('Labels'),
  lfs_object: __('LFS objects'),
  merge_request_attachment: s__('GithubImporter|PR attachments'),
  milestone: __('Milestones'),
  note: __('Notes'),
  note_attachment: s__('GithubImporter|Note links'),
  protected_branch: __('Protected branches'),
  collaborator: s__('GithubImporter|Collaborators'),
  pull_request: s__('GithubImporter|Pull requests'),
  pull_request_merged_by: s__('GithubImporter|PR mergers'),
  pull_request_review: s__('GithubImporter|PR reviews'),
  pull_request_review_request: s__('GithubImporter|PR reviewers'),
  release: __('Releases'),
  release_attachment: s__('GithubImporter|Release links'),
};

// support both camel case and snake case versions
Object.assign(STATISTIC_ITEMS, convertObjectPropsToCamelCase(STATISTIC_ITEMS));

export { STATISTIC_ITEMS };
