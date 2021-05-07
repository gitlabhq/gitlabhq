import { clientTypenames } from '~/import_entities/import_groups/graphql/client_factory';

export const generateFakeEntry = ({ id, status, ...rest }) => ({
  __typename: clientTypenames.BulkImportSourceGroup,
  web_url: `https://fake.host/${id}`,
  full_path: `fake_group_${id}`,
  full_name: `fake_name_${id}`,
  import_target: {
    target_namespace: 'root',
    new_name: `group${id}`,
  },
  id,
  progress: {
    id: `test-${id}`,
    status,
  },
  validation_errors: [],
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

export const availableNamespacesFixture = [
  { id: 24, full_path: 'Commit451' },
  { id: 22, full_path: 'gitlab-org' },
  { id: 23, full_path: 'gnuwget' },
  { id: 25, full_path: 'jashkenas' },
];
