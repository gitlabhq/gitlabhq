import { s__, __ } from '~/locale';

export const integrationLevels = {
  PROJECT: 'project',
  GROUP: 'group',
  INSTANCE: 'instance',
};

export const defaultIntegrationLevel = integrationLevels.INSTANCE;

export const overrideDropdownDescriptions = {
  [integrationLevels.GROUP]: s__(
    'Integrations|Default settings are inherited from the group level.',
  ),
  [integrationLevels.INSTANCE]: s__(
    'Integrations|Default settings are inherited from the instance level.',
  ),
};

export const I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE = s__(
  'Integrations|Connection failed. Check your integration settings.',
);
export const I18N_DEFAULT_ERROR_MESSAGE = __('Something went wrong on our end.');
export const I18N_SUCCESSFUL_CONNECTION_MESSAGE = s__('Integrations|Connection successful.');

export const settingsTabTitle = __('Settings');
export const overridesTabTitle = s__('Integrations|Projects using custom settings');

export const integrationFormSections = {
  CONFIGURATION: 'configuration',
  CONNECTION: 'connection',
  JIRA_TRIGGER: 'jira_trigger',
  JIRA_ISSUES: 'jira_issues',
  JIRA_ISSUE_CREATION: 'jira_issue_creation',
  TRIGGER: 'trigger',
  APPLE_APP_STORE: 'apple_app_store',
  GOOGLE_PLAY: 'google_play',
  GOOGLE_ARTIFACT_MANAGEMENT: 'google_artifact_management',
  GOOGLE_CLOUD_IAM: 'google_cloud_iam',
};

export const integrationFormSectionComponents = {
  [integrationFormSections.CONFIGURATION]: 'IntegrationSectionConfiguration',
  [integrationFormSections.CONNECTION]: 'IntegrationSectionConnection',
  [integrationFormSections.JIRA_TRIGGER]: 'IntegrationSectionJiraTrigger',
  [integrationFormSections.JIRA_ISSUES]: 'IntegrationSectionJiraIssues',
  [integrationFormSections.JIRA_ISSUE_CREATION]: 'IntegrationSectionJiraIssueCreation',
  [integrationFormSections.TRIGGER]: 'IntegrationSectionTrigger',
  [integrationFormSections.APPLE_APP_STORE]: 'IntegrationSectionAppleAppStore',
  [integrationFormSections.GOOGLE_PLAY]: 'IntegrationSectionGooglePlay',
  [integrationFormSections.GOOGLE_ARTIFACT_MANAGEMENT]:
    'IntegrationSectionGoogleArtifactManagement',
  [integrationFormSections.GOOGLE_CLOUD_IAM]: 'IntegrationSectionGoogleCloudIAM',
};

export const integrationTriggerEvents = {
  PUSH: 'push_events',
  ISSUE: 'issues_events',
  CONFIDENTIAL_ISSUE: 'confidential_issues_events',
  MERGE_REQUEST: 'merge_requests_events',
  NOTE: 'note_events',
  CONFIDENTIAL_NOTE: 'confidential_note_events',
  TAG_PUSH: 'tag_push_events',
  PIPELINE: 'pipeline_events',
  WIKI_PAGE: 'wiki_page_events',
  DEPLOYMENT: 'deployment_events',
  ALERT: 'alert_events',
  INCIDENT: 'incident_events',
  GROUP_MENTION: 'group_mention_events',
  GROUP_CONFIDENTIAL_MENTION: 'group_confidential_mention_events',
};

export const integrationTriggerEventTitles = {
  [integrationTriggerEvents.PUSH]: s__('IntegrationEvents|A push is made to the repository'),
  [integrationTriggerEvents.ISSUE]: s__(
    'IntegrationEvents|An issue is created, closed, or reopened',
  ),
  [integrationTriggerEvents.CONFIDENTIAL_ISSUE]: s__(
    'IntegrationEvents|A confidential issue is created, closed, or reopened',
  ),
  [integrationTriggerEvents.MERGE_REQUEST]: s__(
    'IntegrationEvents|A merge request is created, merged, closed, or reopened',
  ),
  [integrationTriggerEvents.NOTE]: s__('IntegrationEvents|A comment is added'),
  [integrationTriggerEvents.CONFIDENTIAL_NOTE]: s__(
    'IntegrationEvents|An internal note or comment on a confidential issue is added',
  ),
  [integrationTriggerEvents.TAG_PUSH]: s__(
    'IntegrationEvents|A tag is pushed to the repository or removed',
  ),
  [integrationTriggerEvents.PIPELINE]: s__('IntegrationEvents|A pipeline status changes'),
  [integrationTriggerEvents.WIKI_PAGE]: s__('IntegrationEvents|A wiki page is created or updated'),
  [integrationTriggerEvents.DEPLOYMENT]: s__(
    'IntegrationEvents|A deployment is started or finished',
  ),
  [integrationTriggerEvents.ALERT]: s__('IntegrationEvents|A new, unique alert is recorded'),
  [integrationTriggerEvents.INCIDENT]: s__(
    'IntegrationEvents|An incident is created, closed, or reopened',
  ),
  [integrationTriggerEvents.GROUP_MENTION]: s__(
    'IntegrationEvents|A group is mentioned in a public context',
  ),
  [integrationTriggerEvents.GROUP_CONFIDENTIAL_MENTION]: s__(
    'IntegrationEvents|A group is mentioned in a confidential context',
  ),
};

export const billingPlans = {
  PREMIUM: 'premium',
  ULTIMATE: 'ultimate',
};

export const billingPlanNames = {
  [billingPlans.PREMIUM]: s__('BillingPlans|Premium'),
  [billingPlans.ULTIMATE]: s__('BillingPlans|Ultimate'),
};

const INTEGRATION_TYPE_SLACK = 'slack';
const INTEGRATION_TYPE_SLACK_APPLICATION = 'gitlab_slack_application';
const INTEGRATION_TYPE_MATTERMOST = 'mattermost';

export const placeholderForType = {
  [INTEGRATION_TYPE_SLACK]: __('#general, #development'),
  [INTEGRATION_TYPE_SLACK_APPLICATION]: __('#general, #development'),
  [INTEGRATION_TYPE_MATTERMOST]: __('my-channel'),
};

export const INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY =
  'google_cloud_platform_artifact_registry';
export const INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_IAM =
  'google_cloud_platform_workload_identity_federation';
export const INTEGRATION_FORM_TYPE_JIRA = 'jira';
export const INTEGRATION_FORM_TYPE_SLACK = 'gitlab_slack_application';

export const jiraIntegrationAuthFields = {
  AUTH_TYPE: 'jira_auth_type',
  USERNAME: 'username',
  PASSWORD: 'password',
};
export const jiraAuthTypeFieldProps = [
  {
    username: s__('JiraService|Email or username'),
    password: s__('JiraService|API token or password'),
    passwordHelp: s__(
      'JiraService|API token for Jira Cloud or password for Jira Data Center and Jira Server',
    ),
    nonEmptyPassword: s__('JiraService|New API token or password'),
  },
  {
    password: s__('JiraService|Jira personal access token'),
    nonEmptyPassword: s__('JiraService|New Jira personal access token'),
  },
];
