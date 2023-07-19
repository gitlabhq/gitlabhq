import { organizationProjects } from 'jest/organizations/groups_and_projects/components/mock_data';

export default {
  Query: {
    organization: async () => {
      // Simulate API loading
      await new Promise((resolve) => {
        setTimeout(resolve, 1000);
      });

      return organizationProjects;
    },
  },
};
