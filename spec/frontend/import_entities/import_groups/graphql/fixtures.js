import { STATUSES } from '~/import_entities/constants';
import { clientTypenames } from '~/import_entities/import_groups/graphql/client_factory';

export const generateFakeEntry = ({ id, status, message, ...rest }) => ({
  __typename: clientTypenames.BulkImportSourceGroup,
  webUrl: `https://fake.host/${id}`,
  fullPath: `fake_group_${id}`,
  fullName: `fake_name_${id}`,
  lastImportTarget: {
    id,
    targetNamespace: 'root',
    newName: `group${id}`,
  },
  id,
  progress:
    status === STATUSES.NONE || status === STATUSES.PENDING
      ? null
      : {
          __typename: clientTypenames.BulkImportProgress,
          id,
          status,
          message: message || '',
        },
  ...rest,
});

export const statusEndpointFixture = {
  importable_data: [
    {
      id: 2595438,
      full_name: 'AutoBreakfast',
      full_path: 'auto-breakfast',
      web_url: 'https://gitlab.com/groups/auto-breakfast',
    },
    {
      id: 4347861,
      full_name: 'GitLab Data',
      full_path: 'gitlab-data',
      web_url: 'https://gitlab.com/groups/gitlab-data',
    },
    {
      id: 5723700,
      full_name: 'GitLab Services',
      full_path: 'gitlab-services',
      web_url: 'https://gitlab.com/groups/gitlab-services',
    },
    {
      id: 349181,
      full_name: 'GitLab-examples',
      full_path: 'gitlab-examples',
      web_url: 'https://gitlab.com/groups/gitlab-examples',
    },
  ],
  version_validation: {
    features: {
      project_migration: { available: false, min_version: '14.8.0' },
      source_instance_version: '14.6.0',
    },
  },
};

const makeGroupMock = ({ id, fullPath }) => ({
  id,
  fullPath,
  name: fullPath,
  visibility: 'public',
  webUrl: `http://gdk.test:3000/groups/${fullPath}`,
  __typename: 'Group',
});

export const AVAILABLE_NAMESPACES = [
  makeGroupMock({ id: 24, fullPath: 'Commit451' }),
  makeGroupMock({ id: 22, fullPath: 'gitlab-org' }),
  makeGroupMock({ id: 23, fullPath: 'gnuwget' }),
  makeGroupMock({ id: 25, fullPath: 'jashkenas' }),
];

export const availableNamespacesFixture = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      groups: {
        nodes: AVAILABLE_NAMESPACES,
        __typename: 'GroupConnection',
      },
      namespace: {
        id: 'gid://gitlab/Namespaces::UserNamespace/1',
        fullPath: 'root',
        __typename: 'Namespace',
      },
      __typename: 'UserCore',
    },
  },
};
