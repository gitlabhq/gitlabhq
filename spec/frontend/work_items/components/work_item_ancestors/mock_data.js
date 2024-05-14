export const mockDisclosureHierarchyItems = [
  {
    title: 'First',
    icon: 'epic',
    href: '#',
  },
  {
    title: 'Second',
    icon: 'epic',
    href: '#',
  },
  {
    title: 'Third',
    icon: 'epic',
    href: '#',
  },
  {
    title: 'Fourth',
    icon: 'epic',
    href: '#',
  },
  {
    title: 'Fifth',
    icon: 'issues',
    href: '#',
  },
  {
    title: 'Sixth',
    icon: 'issues',
    href: '#',
  },
  {
    title: 'Seventh',
    icon: 'issues',
    href: '#',
  },
  {
    title: 'Eighth',
    icon: 'issue-type-task',
    href: '#',
    disabled: true,
  },
  {
    title: 'Ninth',
    icon: 'issue-type-task',
    href: '#',
  },
  {
    title: 'Tenth',
    icon: 'issue-type-task',
    href: '#',
  },
];

export const workItemAncestorsQueryResponse = {
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      title: 'Test',
      widgets: [
        {
          __typename: 'WorkItemWidgetHierarchy',
          type: 'HIERARCHY',
          parent: {
            id: 'gid://gitlab/Issue/1',
          },
          ancestors: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/444',
                iid: '4',
                reference: '#40',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                confidential: false,
                title: '123',
                state: 'OPEN',
                webUrl: '/gitlab-org/gitlab-test/-/work_items/4',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/2',
                  name: 'Issue',
                  iconName: 'issue-type-issue',
                },
              },
            ],
          },
        },
      ],
    },
  },
};

export const workItemThreeAncestorsQueryResponse = {
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      title: 'Test',
      workItemType: {
        __typename: 'WorkItemType',
        id: 'gid://gitlab/WorkItems::Type/5',
        name: 'Task',
        iconName: 'issue-type-task',
      },
      widgets: [
        {
          __typename: 'WorkItemWidgetHierarchy',
          type: 'HIERARCHY',
          parent: {
            id: 'gid://gitlab/Issue/1',
          },
          ancestors: {
            nodes: [
              {
                id: 'gid://gitlab/WorkItem/444',
                iid: '4',
                reference: '#40',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                confidential: false,
                title: '123',
                state: 'OPEN',
                webUrl: '/gitlab-org/gitlab-test/-/work_items/4',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/2',
                  name: 'Issue',
                  iconName: 'issue-type-issue',
                },
              },
              {
                id: 'gid://gitlab/WorkItem/445',
                iid: '5',
                reference: '#41',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                confidential: false,
                title: '1234',
                state: 'OPEN',
                webUrl: '/gitlab-org/gitlab-test/-/work_items/5',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/2',
                  name: 'Issue',
                  iconName: 'issue-type-issue',
                },
              },
              {
                id: 'gid://gitlab/WorkItem/446',
                iid: '6',
                reference: '#42',
                createdAt: '2022-08-03T12:41:54Z',
                closedAt: null,
                confidential: false,
                title: '12345',
                state: 'OPEN',
                webUrl: '/gitlab-org/gitlab-test/-/work_items/6',
                workItemType: {
                  id: 'gid://gitlab/WorkItems::Type/2',
                  name: 'Epic',
                  iconName: 'issue-type-epic',
                },
              },
            ],
          },
        },
      ],
    },
  },
};

export const workItemEmptyAncestorsQueryResponse = {
  data: {
    workItem: {
      __typename: 'WorkItem',
      id: 'gid://gitlab/WorkItem/1',
      title: 'Test',
      workItemType: {
        __typename: 'WorkItemType',
        id: 'gid://gitlab/WorkItems::Type/5',
        name: 'Task',
        iconName: 'issue-type-task',
      },
      widgets: [
        {
          __typename: 'WorkItemWidgetHierarchy',
          type: 'HIERARCHY',
          parent: {
            id: null,
          },
          ancestors: {
            nodes: [],
          },
        },
      ],
    },
  },
};
