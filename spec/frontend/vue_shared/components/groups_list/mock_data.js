import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

export const groups = [
  {
    id: 1,
    fullName: 'Gitlab Org',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/gitlab-org',
    descriptionHtml:
      '<p data-sourcepos="1:1-1:64" dir="auto">Dolorem dolorem omnis impedit cupiditate pariatur officia velit. Fusce eget orci a ipsum tempus vehicula. Donec rhoncus ante sed lacus pharetra, vitae imperdiet felis lobortis. Donec maximus dapibus orci, sit amet euismod dolor rhoncus vel. In nec mauris nibh.</p>',
    avatarUrl: 'avatar.jpg',
    avatarLabel: 'Gitlab Org',
    descendantGroupsCount: 1,
    projectsCount: 1,
    groupMembersCount: 2,
    visibility: 'internal',
    accessLevel: {
      integerValue: 10,
    },
    editPath: 'http://127.0.0.1:3000/groups/gitlab-org/-/edit',
    availableActions: [ACTION_EDIT, ACTION_DELETE],
    createdAt: '2023-09-19T14:42:38Z',
    updatedAt: '2024-04-24T03:47:38Z',
    lastActivityAt: '2024-05-24T03:47:38Z',
    isLinkedToSubscription: false,
  },
  {
    id: 2,
    fullName: 'Gitlab Org / test subgroup',
    parent: {
      id: 1,
    },
    webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/test-subgroup',
    descriptionHtml: '',
    avatarUrl: null,
    avatarLabel: 'Gitlab Org / test subgroup',
    descendantGroupsCount: 4,
    projectsCount: 4,
    groupMembersCount: 4,
    visibility: 'private',
    accessLevel: {
      integerValue: 20,
    },
    editPath: 'http://127.0.0.1:3000/groups/gitlab-org/test-subgroup/-/edit',
    availableActions: [ACTION_EDIT, ACTION_DELETE],
    createdAt: '2023-09-19T14:42:38Z',
    updatedAt: '2024-04-24T03:47:38Z',
    lastActivityAt: '2024-05-24T03:47:38Z',
    isLinkedToSubscription: false,
  },
];
