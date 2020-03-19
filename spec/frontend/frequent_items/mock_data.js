import { TEST_HOST } from 'helpers/test_constants';

export const mockFrequentProjects = [
  {
    id: 1,
    name: 'GitLab Community Edition',
    namespace: 'gitlab-org / gitlab-ce',
    webUrl: `${TEST_HOST}/gitlab-org/gitlab-foss`,
    avatarUrl: null,
    frequency: 1,
    lastAccessedOn: Date.now(),
  },
  {
    id: 2,
    name: 'GitLab CI',
    namespace: 'gitlab-org / gitlab-ci',
    webUrl: `${TEST_HOST}/gitlab-org/gitlab-ci`,
    avatarUrl: null,
    frequency: 9,
    lastAccessedOn: Date.now(),
  },
  {
    id: 3,
    name: 'Typeahead.Js',
    namespace: 'twitter / typeahead-js',
    webUrl: `${TEST_HOST}/twitter/typeahead-js`,
    avatarUrl: '/uploads/-/system/project/avatar/7/TWBS.png',
    frequency: 2,
    lastAccessedOn: Date.now(),
  },
  {
    id: 4,
    name: 'Intel',
    namespace: 'platform / hardware / bsp / intel',
    webUrl: `${TEST_HOST}/platform/hardware/bsp/intel`,
    avatarUrl: null,
    frequency: 3,
    lastAccessedOn: Date.now(),
  },
  {
    id: 5,
    name: 'v4.4',
    namespace: 'platform / hardware / bsp / kernel / common / v4.4',
    webUrl: `${TEST_HOST}/platform/hardware/bsp/kernel/common/v4.4`,
    avatarUrl: null,
    frequency: 8,
    lastAccessedOn: Date.now(),
  },
];

export const mockProject = {
  id: 1,
  name: 'GitLab Community Edition',
  namespace: 'gitlab-org / gitlab-ce',
  webUrl: `${TEST_HOST}/gitlab-org/gitlab-foss`,
  avatarUrl: null,
};
