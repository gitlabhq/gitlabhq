import { s__ } from '~/locale';

export const BRANCH_FILTER_ALL_BRANCHES = 'all_branches';
export const BRANCH_FILTER_WILDCARD = 'wildcard';
export const BRANCH_FILTER_REGEX = 'regex';

export const WILDCARD_CODE_STABLE = '*-stable';
export const WILDCARD_CODE_PRODUCTION = 'production/*';

export const REGEX_CODE = '^(feature|hotfix)/';

export const descriptionText = {
  [BRANCH_FILTER_WILDCARD]: s__(
    'Webhooks|Wildcards such as %{WILDCARD_CODE_STABLE} or %{WILDCARD_CODE_PRODUCTION} are supported.',
  ),
  [BRANCH_FILTER_REGEX]: s__('Webhooks|Regular expressions such as %{REGEX_CODE} are supported.'),
};

export const MASK_ITEM_VALUE_HIDDEN = '************';

export const CUSTOM_HEADER_KEY_PATTERN = /^[A-Za-z]+[0-9]*(?:[._-][A-Za-z0-9]+)*$/;

export const TRIGGER_CONFIG = [
  {
    key: 'tagPushEvents',
    inputName: 'hook[tag_push_events]',
    label: s__('WebhooksTrigger|Tag push events'),
    helpText: s__('WebhooksTrigger|A new tag is pushed to the repository.'),
  },
  {
    key: 'noteEvents',
    inputName: 'hook[note_events]',
    label: s__('WebhooksTrigger|Comments'),
    helpText: s__('WebhooksTrigger|A comment is made or edited on an issue or merge request.'),
  },
  {
    key: 'confidentialNoteEvents',
    inputName: 'hook[confidential_note_events]',
    label: s__('WebhooksTrigger|Confidential comments'),
    helpText: s__('WebhooksTrigger|A comment is made or edited on a confidential issue.'),
  },
  {
    key: 'issuesEvents',
    inputName: 'hook[issues_events]',
    label: s__('WebhooksTrigger|Issues events'),
    helpText: s__('WebhooksTrigger|An issue is created, updated, closed, or reopened.'),
  },
  {
    key: 'confidentialIssuesEvents',
    inputName: 'hook[confidential_issues_events]',
    label: s__('WebhooksTrigger|Confidential issues events'),
    helpText: s__('WebhooksTrigger|A confidential issue is created, updated, closed, or reopened.'),
  },
  {
    key: 'mergeRequestsEvents',
    inputName: 'hook[merge_requests_events]',
    label: s__('WebhooksTrigger|Merge request events'),
    helpText: s__('WebhooksTrigger|A merge request is created, updated, or merged.'),
  },
  {
    key: 'jobEvents',
    inputName: 'hook[job_events]',
    label: s__('WebhooksTrigger|Job events'),
    helpText: s__("WebhooksTrigger|A job's status changes."),
  },
  {
    key: 'pipelineEvents',
    inputName: 'hook[pipeline_events]',
    label: s__('WebhooksTrigger|Pipeline events'),
    helpText: s__("WebhooksTrigger|A pipeline's status changes."),
  },
  {
    key: 'wikiPageEvents',
    inputName: 'hook[wiki_page_events]',
    label: s__('WebhooksTrigger|Wiki page events'),
    helpText: s__('WebhooksTrigger|A wiki page is created or updated.'),
  },
  {
    key: 'deploymentEvents',
    inputName: 'hook[deployment_events]',
    label: s__('WebhooksTrigger|Deployment events'),
    helpText: s__('WebhooksTrigger|A deployment starts, finishes, fails, or is canceled.'),
  },
  {
    key: 'featureFlagEvents',
    inputName: 'hook[feature_flag_events]',
    label: s__('WebhooksTrigger|Feature flag events'),
    helpText: s__('WebhooksTrigger|A feature flag is turned on or off.'),
  },
  {
    key: 'releasesEvents',
    inputName: 'hook[releases_events]',
    label: s__('WebhooksTrigger|Releases events'),
    helpText: s__('WebhooksTrigger|A release is created, updated, or deleted.'),
  },
  {
    key: 'milestoneEvents',
    inputName: 'hook[milestone_events]',
    label: s__('WebhooksTrigger|Milestone events'),
    helpText: s__('WebhooksTrigger|A milestone is created, closed, reopened, or deleted.'),
  },
  {
    key: 'emojiEvents',
    inputName: 'hook[emoji_events]',
    label: s__('WebhooksTrigger|Emoji events'),
    helpText: s__('WebhooksTrigger|An emoji is awarded or revoked.'),
    helpLink: {
      text: s__('WebhooksTrigger|Which emoji events trigger webhooks?'),
      path: 'user/project/integrations/webhook_events.md',
      anchor: 'emoji-events',
    },
  },
  {
    key: 'resourceAccessTokenEvents',
    inputName: 'hook[resource_access_token_events]',
    label: s__('WebhooksTrigger|Resource access token events'),
    helpText: s__('WebhooksTrigger|An access token expires in the next 7 days.'),
    helpLink: {
      text: s__('WebhooksTrigger|Which project or group access token events trigger webhooks?'),
      path: 'user/project/integrations/webhook_events.md',
      anchor: 'project-and-group-access-token-events',
    },
  },
];
