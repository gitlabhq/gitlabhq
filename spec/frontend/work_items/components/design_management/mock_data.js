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
  issue: {
    id: 'gid:/gitlab/Issue/1',
    title: 'My precious issue',
    webPath: 'full-issue-path',
    webUrl: 'full-issue-url',
    participants: {
      nodes: [
        {
          name: 'Administrator',
          id: 'gid://gitlab/User/1"',
          username: 'root',
          webUrl: 'link-to-author',
          webPath: '/root',
          avatarUrl: 'link-to-avatar',
          __typename: 'UserCore',
        },
      ],
      __typename: 'UserCoreConnection',
    },
    userPermissions: {
      createDesign: true,
      updateDesign: true,
      __typename: 'IssuePermissions',
    },
    __typename: 'Issue',
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

export const designDescriptionFactory = ({
  updateDesign = true,
  description = 'Description test',
  descriptionHtml = '<p data-sourcepos="1:1-1:16" dir="auto">Description test</p>',
} = {}) => ({
  id: 'gid:/gitlab/Design/1',
  iid: 1,
  filename: 'test.jpg',
  fullPath: 'full-design-path',
  image: 'test.jpg',
  description,
  descriptionHtml,
  updatedAt: '01-01-2019',
  updatedBy: {
    name: 'test',
  },
  issue: {
    id: 'gid:/gitlab/Issue/1',
    title: 'My precious issue',
    webPath: 'full-issue-path',
    webUrl: 'full-issue-url',
    participants: {
      nodes: [
        {
          name: 'Administrator',
          username: 'root',
          webUrl: 'link-to-author',
          avatarUrl: 'link-to-avatar',
          __typename: 'UserCore',
        },
      ],
      __typename: 'UserCoreConnection',
    },
    userPermissions: {
      updateDesign,
      awardEmoji: true,
      __typename: 'IssuePermissions',
    },
    __typename: 'Issue',
  },
  discussions: {
    nodes: [],
    __typename: 'DiscussionConnection',
  },
  __typename: 'Design',
});

export const allDesignsArchivedResponse = () => ({
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
            designs: { nodes: [] },
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
                  versions: { nodes: mockAllVersions },
                },
              },
            ],
          },
        ],
      },
    },
  },
};

export const mockUpdateDesignDescriptionResponse = (options) => {
  return {
    data: {
      designManagementUpdate: {
        errors: [],
        design: designDescriptionFactory(options),
      },
      __typename: 'DesignManagementUpdatePayload',
    },
  };
};

export const mockArchiveDesignMutationResponse = {
  data: {
    designManagementDelete: {
      version: {
        id: 'gid://gitlab/DesignManagement::Version/45',
        sha: '9c325d6ebff28c5316360e2c40939ceaf0e7560e',
        createdAt: '2024-10-02T18:56:41Z',
        author: {
          id: 'gid://gitlab/User/1',
          name: 'Administrator',
          avatarUrl:
            'https://www.gravatar.com/avatar/fb95b2f29af5fa93521f6aa719fd7216f539d2ba41c7188e8925af9dfac16d44?s=80&d=identicon',
          __typename: 'UserCore',
        },
        __typename: 'DesignVersion',
      },
      errors: [],
      __typename: 'DesignManagementDeletePayload',
    },
  },
};
