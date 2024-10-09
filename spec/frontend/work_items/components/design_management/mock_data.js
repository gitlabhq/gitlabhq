export const mockDesign = {
  id: 'gid://gitlab/DesignManagement::Design/33',
  event: 'NONE',
  filename: 'Screenshot_from_2024-03-28_10-24-43.png',
  notesCount: 0,
  description: 'Description test',
  descriptionHtml: '<p>Description test</p>',
  image: 'raw_image_1',
  imageV432x230: 'resized_image_v432x230_1',
  fullPath: 'designs/issue-2/Screenshot_from_2024-03-28_10-24-43.png',
  currentUserTodos: {
    nodes: [],
    __typename: 'TodoConnection',
  },
  discussions: {
    nodes: [],
    __typename: 'DiscussionConnection',
  },
  __typename: 'Design',
};

export const mockDesign2 = {
  id: 'gid://gitlab/DesignManagement::Design/34',
  event: 'NONE',
  filename: 'Screenshot_from_2024-03-28_10-24-44.png',
  notesCount: 0,
  image: 'raw_image_2',
  imageV432x230: 'resized_image_v432x230_2',
  currentUserTodos: {
    nodes: [],
    __typename: 'TodoConnection',
  },
  __typename: 'Design',
};

export const mockAllVersions = [
  {
    __typename: 'DesignVersion',
    id: 'gid://gitlab/DesignManagement::Version/1',
    sha: 'b389071a06c153509e11da1f582005b316667001',
    createdAt: '2021-08-09T06:05:00Z',
    author: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      name: 'Adminstrator',
      avatarUrl: 'avatar.png',
    },
  },
  {
    __typename: 'DesignVersion',
    id: 'gid://gitlab/DesignManagement::Version/2',
    sha: 'b389071a06c153509e11da1f582005b316667021',
    createdAt: '2021-08-09T06:05:00Z',
    author: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      name: 'Adminstrator',
      avatarUrl: 'avatar.png',
    },
  },
];

export const designCollectionResponse = (mockDesigns = [mockDesign]) => ({
  data: {
    workItem: {
      id: 'gid://gitlab/WorkItem/1',
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/1',
        name: 'Issue',
        __typename: 'WorkItemType',
      },
      widgets: [
        {
          __typename: 'WorkItemWidgetDesigns',
          type: 'DESIGNS',
          designCollection: {
            copyState: 'READY',
            designs: { nodes: mockDesigns },
            versions: { nodes: mockAllVersions },
          },
        },
      ],
    },
  },
});

export const getDesignResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      workItems: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/1',
            title: 'Work item 1',
            widgets: [
              {
                __typename: 'WorkItemWidgetDesigns',
                type: 'DESIGNS',
                designCollection: {
                  designs: { nodes: [mockDesign] },
                },
              },
            ],
          },
        ],
      },
    },
  },
};
