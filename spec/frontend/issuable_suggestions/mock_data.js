import { TEST_HOST } from 'helpers/test_constants';

function getDate(daysMinus) {
  const today = new Date();
  today.setDate(today.getDate() - daysMinus);

  return today.toISOString();
}

export default () => ({
  id: 1,
  iid: 1,
  state: 'opened',
  upvotes: 1,
  userNotesCount: 2,
  closedAt: getDate(1),
  createdAt: getDate(3),
  updatedAt: getDate(2),
  confidential: false,
  webUrl: `${TEST_HOST}/test/issue/1`,
  title: 'Test issue',
  author: {
    avatarUrl: `${TEST_HOST}/avatar`,
    name: 'Author Name',
    username: 'author.username',
    webUrl: `${TEST_HOST}/author`,
  },
});
