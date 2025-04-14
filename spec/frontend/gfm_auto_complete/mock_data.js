export const eventlistenersMockDefaultMap = [
  {
    key: 'shown',
    namespace: 'atwho',
  },
  {
    key: 'shown-users',
    namespace: 'atwho',
  },
  {
    key: 'shown-issues',
    namespace: 'atwho',
  },
  {
    key: 'shown-milestones',
    namespace: 'atwho',
  },
  {
    key: 'shown-mergerequests',
    namespace: 'atwho',
  },
  {
    key: 'shown-labels',
    namespace: 'atwho',
  },
  {
    key: 'shown-snippets',
    namespace: 'atwho',
  },
  {
    key: 'shown-contacts',
    namespace: 'atwho',
  },
];

export const crmContactsMock = [
  {
    id: 1,
    email: 'contact.1@email.com',
    first_name: 'Contact',
    last_name: 'One',
    search: 'contact.1@email.com',
    state: 'active',
    set: false,
  },
  {
    id: 2,
    email: 'contact.2@email.com',
    first_name: 'Contact',
    last_name: 'Two',
    search: 'contact.2@email.com',
    state: 'active',
    set: false,
  },
  {
    id: 3,
    email: 'contact.3@email.com',
    first_name: 'Contact',
    last_name: 'Three',
    search: 'contact.3@email.com',
    state: 'inactive',
    set: false,
  },
  {
    id: 4,
    email: 'contact.4@email.com',
    first_name: 'Contact',
    last_name: 'Four',
    search: 'contact.4@email.com',
    state: 'inactive',
    set: true,
  },
  {
    id: 5,
    email: 'contact.5@email.com',
    first_name: 'Contact',
    last_name: 'Five',
    search: 'contact.5@email.com',
    state: 'active',
    set: true,
  },
  {
    id: 5,
    email: 'contact.6@email.com',
    first_name: 'Contact',
    last_name: 'Six',
    search: 'contact.6@email.com',
    state: 'active',
    set: undefined, // On purpose
  },
];

export const mockIssues = [
  {
    title: 'Issue 1',
    iid: 1,
    reference: 'group/project#1',
    workItemType: { iconName: 'issues' },
  },
  {
    title: 'Issue 2',
    iid: 2,
    reference: 'group/project#2',
    workItemType: { iconName: 'issues' },
  },
];

export const mockAssignees = [
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl: '',
    name: 'Administrator',
    username: 'root',
    webUrl: 'http://127.0.0.1:3000/root',
    webPath: '/root',
  },
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/9',
    avatarUrl: '',
    name: 'Carla Weissnat',
    username: 'milford',
    webUrl: 'http://127.0.0.1:3000/milford',
    webPath: '/milford',
  },
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/16',
    avatarUrl: '',
    name: 'Carol Hagenes',
    username: 'nancee_simonis',
    webUrl: 'http://127.0.0.1:3000/nancee_simonis',
    webPath: '/nancee_simonis',
  },
];
