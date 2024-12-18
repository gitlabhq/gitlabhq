import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';

export const formatProjects = (projects) =>
  formatGraphQLProjects(projects, (project) => ({
    editPath: `${project.webUrl}/edit`,
  }));
