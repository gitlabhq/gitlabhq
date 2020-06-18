import getJiraImportDetailsQuery from '~/jira_import/queries/get_jira_import_details.query.graphql';
import { IMPORT_STATE } from '~/jira_import/utils/jira_import_utils';

export const fullPath = 'gitlab-org/gitlab-test';

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
