export const generateCatalogSettingsResponse = (
  isCatalogResource = false,
  { description = 'A project description' } = {},
) => {
  return {
    data: {
      project: {
        id: 'gid://gitlab/Project/149',
        isCatalogResource,
        description,
      },
    },
  };
};
