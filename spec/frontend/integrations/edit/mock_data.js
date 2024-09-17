export const mockIntegrationProps = {
  id: 25,
  initialActivated: true,
  manualActivation: true,
  editable: true,
  triggerFieldsProps: {
    initialTriggerCommit: false,
    initialTriggerMergeRequest: false,
    initialEnableComments: false,
  },
  jiraIssuesProps: {},
  triggerEvents: [
    { name: 'push_events', title: 'Push', value: true },
    { name: 'issues_events', title: 'Issue', value: true },
  ],
  sections: [],
  fields: [],
  type: '',
  inheritFromId: 25,
  integrationLevel: 'project',
};

export const mockJiraIssueTypes = [
  { id: '1', name: 'issue', description: 'issue' },
  { id: '2', name: 'bug', description: 'bug' },
  { id: '3', name: 'epic', description: 'epic' },
];

export const mockJiraAuthFields = [
  {
    name: 'jira_auth_type',
    type: 'select',
    title: 'Authentication type',
  },
  {
    name: 'username',
    type: 'text',
    help: 'Email for Jira Cloud or username for Jira Data Center and Jira Server',
  },
  {
    name: 'password',
    type: 'password',
    help: 'API token for Jira Cloud or password for Jira Data Center and Jira Server',
  },
];

export const mockField = {
  help: 'The URL of the project',
  name: 'project_url',
  placeholder: 'https://jira.example.com',
  title: 'Project URL',
  type: 'text',
  value: '1',
};

export const mockSectionConnection = {
  type: 'connection',
  title: 'Connection details',
  description: 'Learn more on how to configure this integration.',
};

export const mockSectionJiraIssues = {
  type: 'jira_issues',
  title: 'Issues',
  description:
    'Work on Jira issues without leaving GitLab. Add a Jira menu to access a read-only list of your Jira issues. Learn more.',
  plan: 'premium',
};
