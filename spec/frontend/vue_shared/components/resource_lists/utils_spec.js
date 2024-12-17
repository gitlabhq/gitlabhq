import organizationProjectsGraphQlResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import {
  deleteParams,
  renderDeleteSuccessToast,
} from '~/vue_shared/components/resource_lists/utils';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const {
  data: {
    organization: {
      projects: { nodes: projects },
    },
  },
} = organizationProjectsGraphQlResponse;

describe('renderDeleteSuccessToast', () => {
  const [MOCK_PROJECT] = formatGraphQLProjects(projects);
  const MOCK_TYPE = 'Project';

  it('calls toast correctly', () => {
    renderDeleteSuccessToast(MOCK_PROJECT, MOCK_TYPE);

    expect(toast).toHaveBeenCalledWith(`${MOCK_TYPE} '${MOCK_PROJECT.name}' is being deleted.`);
  });
});

describe('deleteParams', () => {
  it('returns {} always', () => {
    expect(deleteParams()).toStrictEqual({});
  });
});
