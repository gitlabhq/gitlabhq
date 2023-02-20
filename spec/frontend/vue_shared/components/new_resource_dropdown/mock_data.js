export const emptySearchProjectsQueryResponse = {
  data: {
    projects: {
      nodes: [],
    },
  },
};

export const emptySearchProjectsWithinGroupQueryResponse = {
  data: {
    group: {
      id: '1',
      projects: emptySearchProjectsQueryResponse.data.projects,
    },
  },
};

export const project1 = {
  id: 'gid://gitlab/Group/26',
  name: 'Super Mario Project',
  nameWithNamespace: 'Mushroom Kingdom / Super Mario Project',
  webUrl: 'https://127.0.0.1:3000/mushroom-kingdom/super-mario-project',
};

export const project2 = {
  id: 'gid://gitlab/Group/59',
  name: 'Mario Kart Project',
  nameWithNamespace: 'Mushroom Kingdom / Mario Kart Project',
  webUrl: 'https://127.0.0.1:3000/mushroom-kingdom/mario-kart-project',
};

export const project3 = {
  id: 'gid://gitlab/Group/103',
  name: 'Mario Party Project',
  nameWithNamespace: 'Mushroom Kingdom / Mario Party Project',
  webUrl: 'https://127.0.0.1:3000/mushroom-kingdom/mario-party-project',
};

export const searchProjectsQueryResponse = {
  data: {
    projects: {
      nodes: [project1, project2, project3],
    },
  },
};

export const searchProjectsWithinGroupQueryResponse = {
  data: {
    group: {
      id: '1',
      projects: searchProjectsQueryResponse.data.projects,
    },
  },
};
