import { TEST_HOST } from './test_constants';

export const createGon = (IS_EE) => {
  return {
    gitlab_url: TEST_HOST,
    relative_url_root: '',
    ee: IS_EE,
    default_avatar_url: `${TEST_HOST}/default_avatar.png`,
  };
};
