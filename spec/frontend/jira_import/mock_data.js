import getJiraImportDetailsQuery from '~/jira_import/queries/get_jira_import_details.query.graphql';
import { userMappingsPageSize } from '~/jira_import/utils/constants';
import { IMPORT_STATE } from '~/jira_import/utils/jira_import_utils';

export const fullPath = 'gitlab-org/gitlab-test';

export const issuesPath = 'gitlab-org/gitlab-test/-/issues';

export const illustration = 'illustration.svg';

export const jiraIntegrationPath = 'gitlab-org/gitlab-test/-/services/jira/edit';

export const projectId = '5';

export const projectPath = 'gitlab-org/gitlab-test';

export const queryDetails = {
  query: getJiraImportDetailsQuery,
  variables: {
    fullPath,
  },
};

export const jiraImportDetailsQueryResponse = {
  project: {
    jiraImportStatus: IMPORT_STATE.NONE,
    jiraImports: {
      nodes: [
        {
          jiraProjectKey: 'MJP',
          scheduledAt: '2020-01-01T12:34:56Z',
          scheduledBy: {
            name: 'Jane Doe',
            __typename: 'User',
          },
          __typename: 'JiraImport',
        },
      ],
      __typename: 'JiraImportConnection',
    },
    services: {
      nodes: [
        {
          projects: {
            nodes: [
              {
                key: 'MJP',
                name: 'My Jira Project',
                __typename: 'JiraProject',
              },
              {
                key: 'MTG',
                name: 'Migrate To GitLab',
                __typename: 'JiraProject',
              },
            ],
            __typename: 'JiraProjectConnection',
          },
          __typename: 'JiraService',
        },
      ],
      __typename: 'ServiceConnection',
    },
    __typename: 'Project',
  },
};

export const jiraImportMutationResponse = {
  jiraImportStart: {
    clientMutationId: null,
    jiraImport: {
      jiraProjectKey: 'MTG',
      scheduledAt: '2020-02-02T20:20:20Z',
      scheduledBy: {
        name: 'John Doe',
        __typename: 'User',
      },
      __typename: 'JiraImport',
    },
    errors: [],
    __typename: 'JiraImportStartPayload',
  },
};

export const jiraProjects = [
  { text: 'My Jira Project (MJP)', value: 'MJP' },
  { text: 'My Second Jira Project (MSJP)', value: 'MSJP' },
  { text: 'Migrate to GitLab (MTG)', value: 'MTG' },
];

export const jiraUsersResponse = new Array(userMappingsPageSize);

export const imports = [
  {
    jiraProjectKey: 'MTG',
    scheduledAt: '2020-04-08T10:11:12+00:00',
    scheduledBy: {
      name: 'John Doe',
    },
  },
  {
    jiraProjectKey: 'MSJP',
    scheduledAt: '2020-04-09T13:14:15+00:00',
    scheduledBy: {
      name: 'Jimmy Doe',
    },
  },
  {
    jiraProjectKey: 'MTG',
    scheduledAt: '2020-04-09T16:17:18+00:00',
    scheduledBy: {
      name: 'Jane Doe',
    },
  },
];

export const userMappings = [
  {
    jiraAccountId: 'aei23f98f-q23fj98qfj',
    jiraDisplayName: 'Jane Doe',
    jiraEmail: 'janedoe@example.com',
    gitlabId: 15,
    gitlabUsername: 'janedoe',
  },
  {
    jiraAccountId: 'fu39y8t34w-rq3u289t3h4i',
    jiraDisplayName: 'Fred Chopin',
    jiraEmail: 'fredchopin@example.com',
    gitlabId: undefined,
    gitlabUsername: undefined,
  },
];
