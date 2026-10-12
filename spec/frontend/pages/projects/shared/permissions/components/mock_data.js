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

export const generateCatalogResourceUsageResponse = (last30DayUsageCount = 0) => {
  return {
    data: {
      ciCatalogResource: {
        id: 'gid://gitlab/Ci::Catalog::Resource/39',
        last30DayUsageCount,
      },
    },
  };
};
