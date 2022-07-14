export const propsData = {
  id: '1',
  rootId: '1',
  name: 'test name',
  isProject: false,
  accessLevels: { Guest: 10, Reporter: 20, Developer: 30, Maintainer: 40, Owner: 50 },
  defaultAccessLevel: 30,
  helpLink: 'https://example.com',
  tasksToBeDoneOptions: [
    { text: 'First task', value: 'first' },
    { text: 'Second task', value: 'second' },
  ],
  projects: [
    { text: 'First project', value: '1' },
    { text: 'Second project', value: '2' },
  ],
};

export const inviteSource = 'unknown';
export const newProjectPath = 'projects/new';
export const freeUsersLimit = 5;
export const membersCount = 1;

export const user1 = { id: 1, name: 'Name One', username: 'one_1', avatar_url: '' };
export const user2 = { id: 2, name: 'Name Two', username: 'one_2', avatar_url: '' };
export const user3 = {
  id: 'user-defined-token',
  name: 'email@example.com',
  avatar_url: '',
};
export const user4 = {
  id: 'user-defined-token2',
  name: 'email4@example.com',
  avatar_url: '',
};
export const user5 = {
  id: '3',
  username: 'root',
  name: 'root',
  avatar_url: '',
};

export const GlEmoji = { template: '<img/>' };
