export const mockDesign = {
  id: 'gid://gitlab/DesignManagement::Design/33',
  event: 'NONE',
  filename: 'Screenshot_from_2024-03-28_10-24-43.png',
  notesCount: 0,
  image: 'raw_image_1',
  imageV432x230: 'resized_image_v432x230_1',
  currentUserTodos: {
    nodes: [],
    __typename: 'TodoConnection',
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

export const mockVersion = {
  id: 'gid://gitlab/DesignManagement::Version/40',
  sha: 'f03f7c6f421ebb006d210bae9ad9145963a0c48d',
  createdAt: '2024-04-10T02:41:14Z',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    avatarUrl:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    __typename: 'UserCore',
  },
  __typename: 'DesignVersion',
};

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
            versions: { nodes: [mockVersion] },
          },
        },
      ],
    },
  },
});
