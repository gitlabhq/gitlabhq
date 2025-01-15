import organizationProjectsGraphQlResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import {
  availableGraphQLProjectActions,
  deleteParams,
  renderDeleteSuccessToast,
} from '~/vue_shared/components/projects_list/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
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

describe('availableGraphQLProjectActions', () => {
  describe.each`
    userPermissions                                  | availableActions
    ${{ viewEditPage: false, removeProject: false }} | ${[]}
    ${{ viewEditPage: true, removeProject: false }}  | ${[ACTION_EDIT]}
    ${{ viewEditPage: false, removeProject: true }}  | ${[ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: true }}   | ${[ACTION_EDIT, ACTION_DELETE]}
  `('availableGraphQLProjectActions', ({ userPermissions, availableActions }) => {
    it(`when userPermissions = ${JSON.stringify(userPermissions)} then availableActions = [${availableActions}] and is sorted correctly`, () => {
      expect(availableGraphQLProjectActions({ userPermissions })).toStrictEqual(availableActions);
    });
  });
});

describe('renderDeleteSuccessToast', () => {
  const [project] = formatGraphQLProjects(projects);

  it('calls toast correctly', () => {
    renderDeleteSuccessToast(project);

    expect(toast).toHaveBeenCalledWith(`Project '${project.name}' is being deleted.`);
  });
});

describe('deleteParams', () => {
  it('returns empty object', () => {
    expect(deleteParams()).toStrictEqual({});
  });
});
