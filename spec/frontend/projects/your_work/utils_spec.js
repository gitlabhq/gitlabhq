import starredProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/starred_projects.query.graphql.json';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { formatProjects } from '~/projects/your_work/utils';

const {
  data: {
    currentUser: {
      starredProjects: { nodes: projects },
    },
  },
} = starredProjectsGraphQlResponse;

describe('formatProjects', () => {
  it('returns result from formatGraphQLProjects and adds editPath', () => {
    expect(formatProjects(projects)).toEqual(
      formatGraphQLProjects(projects).map((project) => ({
        ...project,
        editPath: `${project.webUrl}/edit`,
      })),
    );
  });
});
