export const generateCatalogSettingsResponse = (isCatalogResource = false) => {
  return {
    data: {
      project: {
        id: 'gid://gitlab/Project/149',
        isCatalogResource,
      },
    },
  };
};
