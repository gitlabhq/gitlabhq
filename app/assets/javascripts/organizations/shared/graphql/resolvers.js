import { organization, organizationProjects, organizationGroups } from '../../mock_data';

export default {
  Query: {
    organization: async () => {
      // Simulate API loading
      await new Promise((resolve) => {
        setTimeout(resolve, 1000);
      });

      return {
        ...organization,
        projects: organizationProjects,
        groups: organizationGroups,
      };
    },
  },
};
