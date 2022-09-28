const usersMock = [
  {
    username: 'usr1',
    webUrl: 'http://test.test/usr1',
    name: 'User 1',
    avatarUrl: 'http://test.test/avt1.png',
  },
  {
    username: 'usr2',
    webUrl: 'http://test.test/usr2',
    name: 'User 2',
    avatarUrl: 'http://test.test/avt2.png',
  },
  {
    username: 'usr3',
    webUrl: 'http://test.test/usr3',
    name: 'User 3',
    avatarUrl: 'http://test.test/avt3.png',
  },
  {
    username: 'usr4',
    webUrl: 'http://test.test/usr4',
    name: 'User 4',
    avatarUrl: 'http://test.test/avt4.png',
  },
  {
    username: 'usr5',
    webUrl: 'http://test.test/usr5',
    name: 'User 5',
    avatarUrl: 'http://test.test/avt5.png',
  },
];

const accessLevelsMock = [
  { accessLevelDescription: 'Administrator' },
  { accessLevelDescription: 'Maintainer' },
];

const groupsMock = [{ name: 'test_group_1' }, { name: 'test_group_2' }];

export const protectionPropsMock = {
  header: 'Test protection',
  headerLinkTitle: 'Test link title',
  headerLinkHref: 'Test link href',
  roles: accessLevelsMock,
  users: usersMock,
  groups: groupsMock,
};

export const protectionRowPropsMock = {
  title: 'Test title',
  users: usersMock,
  accessLevels: accessLevelsMock,
};
