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
export const remainingSeats = 2;

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
export const user6 = {
  id: 'user-defined-token3',
  name: 'email5@example.com',
  avatar_url: '',
};

export const postData = {
  user_id: `${user1.id},${user2.id}`,
  access_level: propsData.defaultAccessLevel,
  expires_at: undefined,
  invite_source: inviteSource,
  format: 'json',
  tasks_to_be_done: [],
  tasks_project_id: '',
};

export const emailPostData = {
  access_level: propsData.defaultAccessLevel,
  expires_at: undefined,
  email: `${user3.name}`,
  invite_source: inviteSource,
  tasks_to_be_done: [],
  tasks_project_id: '',
  format: 'json',
};

export const singleUserPostData = {
  access_level: propsData.defaultAccessLevel,
  expires_at: undefined,
  user_id: `${user1.id}`,
  email: `${user3.name}`,
  invite_source: inviteSource,
  tasks_to_be_done: [],
  tasks_project_id: '',
  format: 'json',
};

export const GlEmoji = { template: '<img/>' };
