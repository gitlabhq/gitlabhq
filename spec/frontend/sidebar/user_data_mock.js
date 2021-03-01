import { TEST_HOST } from 'helpers/test_constants';

export default () => ({
  avatar_url: `${TEST_HOST}/avatar/root.png`,
  id: 1,
  name: 'Root',
  state: 'active',
  username: 'root',
  web_url: `${TEST_HOST}/root`,
  can_merge: true,
  can_update_merge_request: true,
  reviewed: true,
  approved: false,
});
