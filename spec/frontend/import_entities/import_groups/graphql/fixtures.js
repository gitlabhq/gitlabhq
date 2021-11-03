import { STATUSES } from '~/import_entities/constants';
import { clientTypenames } from '~/import_entities/import_groups/graphql/client_factory';

export const generateFakeEntry = ({ id, status, ...rest }) => ({
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
          id,
          status,
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
};

export const availableNamespacesFixture = Object.freeze([
  { id: 24, fullPath: 'Commit451' },
  { id: 22, fullPath: 'gitlab-org' },
  { id: 23, fullPath: 'gnuwget' },
  { id: 25, fullPath: 'jashkenas' },
]);
