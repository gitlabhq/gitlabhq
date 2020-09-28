export const triggers = [
  {
    hasTokenExposed: true,
    token: '0000',
    description: 'My trigger',
    owner: {
      name: 'My User',
      username: 'user1',
      path: '/user1',
    },
    lastUsed: null,
    canAccessProject: true,
    editProjectTriggerPath: '/triggers/1/edit',
    projectTriggerPath: '/trigger/1',
  },
  {
    hasTokenExposed: false,
    token: '1111',
    description: "Anothe user's trigger",
    owner: {
      name: 'Someone else',
      username: 'user2',
      path: '/user2',
    },
    lastUsed: '2020-09-10T08:26:47.410Z',
    canAccessProject: false,
    editProjectTriggerPath: '/triggers/1/edit',
    projectTriggerPath: '/trigger/1',
  },
];
