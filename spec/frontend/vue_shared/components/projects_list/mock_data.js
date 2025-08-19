import projectsGraphQLResponse from 'test_fixtures/graphql/projects/your_work/personal_projects.query.graphql.json';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';

const {
  data: {
    projects: { nodes: graphqlProjects },
  },
} = projectsGraphQLResponse;

const projects = formatGraphQLProjects(graphqlProjects);

export { projects };
