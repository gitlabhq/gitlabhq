export const projectKeys = ['id', 'name', 'organizationName', 'organizationSlug', 'slug'];

export const transformFrontendSettings = ({
  apiHost,
  enabled,
  integrated,
  token,
  selectedProject,
}) => {
  const project = selectedProject
    ? {
        sentry_project_id: selectedProject.id,
        slug: selectedProject.slug,
        name: selectedProject.name,
        organization_name: selectedProject.organizationName,
        organization_slug: selectedProject.organizationSlug,
      }
    : null;

  return { api_host: apiHost || null, enabled, integrated, token: token || null, project };
};

export const getDisplayName = (project) => `${project.organizationName} | ${project.slug}`;
