export const projectKeys = ['name', 'organizationName', 'organizationSlug', 'slug'];

export const transformFrontendSettings = ({ apiHost, enabled, token, selectedProject }) => {
  const project = selectedProject
    ? {
        slug: selectedProject.slug,
        name: selectedProject.name,
        organization_name: selectedProject.organizationName,
        organization_slug: selectedProject.organizationSlug,
      }
    : null;

  return { api_host: apiHost || null, enabled, token: token || null, project };
};

export const getDisplayName = project => `${project.organizationName} | ${project.slug}`;
