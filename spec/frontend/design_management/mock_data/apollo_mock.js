export const mockAuthor = {
  id: 'gid://gitlab/User/1',
  name: 'John',
  webUrl: 'link-to-john-profile',
  avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  username: 'john.doe',
};

export const mockAwardEmoji = {
  __typename: 'AwardEmojiConnection',
  nodes: [
    {
      __typename: 'AwardEmoji',
      name: 'briefcase',
      user: mockAuthor,
    },
    {
      __typename: 'AwardEmoji',
      name: 'baseball',
      user: mockAuthor,
    },
  ],
};

export const designListQueryResponseNodes = [
  {
    __typename: 'Design',
    id: '1',
    event: 'NONE',
    filename: 'fox_1.jpg',
    notesCount: 3,
    image: 'image-1',
    imageV432x230: 'image-1',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
  {
    __typename: 'Design',
    id: '2',
    event: 'NONE',
    filename: 'fox_2.jpg',
    notesCount: 2,
    image: 'image-2',
    imageV432x230: 'image-2',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
  {
    __typename: 'Design',
    id: '3',
    event: 'NONE',
    filename: 'fox_3.jpg',
    notesCount: 1,
    image: 'image-3',
    imageV432x230: 'image-3',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
];

export const getDesignListQueryResponse = ({
  versions = [],
  designs = designListQueryResponseNodes,
} = {}) => ({
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      issue: {
        __typename: 'Issue',
        id: 'issue-1',
        designCollection: {
          __typename: 'DesignCollection',
          copyState: 'READY',
          designs: {
            __typename: 'DesignConnection',
            nodes: designs,
          },
          versions: {
            __typename: 'DesignVersionConnection',
            nodes: versions,
          },
        },
      },
    },
  },
});

export const designUploadMutationCreatedResponse = {
  data: {
    designManagementUpload: {
      designs: [
        {
          id: '1',
          event: 'CREATION',
          filename: 'fox_1.jpg',
        },
      ],
    },
  },
};

export const designUploadMutationUpdatedResponse = {
  data: {
    designManagementUpload: {
      designs: [
        {
          id: '1',
          event: 'MODIFICATION',
          filename: 'fox_1.jpg',
        },
      ],
    },
  },
};

export const getPermissionsQueryResponse = (createDesign = true) => ({
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      issue: {
        __typename: 'Issue',
        id: 'issue-1',
        userPermissions: { __typename: 'UserPermissions', createDesign },
      },
    },
  },
});

export const reorderedDesigns = [
  {
    __typename: 'Design',
    id: '2',
    event: 'NONE',
    filename: 'fox_2.jpg',
    notesCount: 2,
    image: 'image-2',
    imageV432x230: 'image-2',
    description: '',
    descriptionHtml: '',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
  {
    __typename: 'Design',
    id: '1',
    event: 'NONE',
    filename: 'fox_1.jpg',
    notesCount: 3,
    image: 'image-1',
    imageV432x230: 'image-1',
    description: '',
    descriptionHtml: '',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
  {
    __typename: 'Design',
    id: '3',
    event: 'NONE',
    filename: 'fox_3.jpg',
    notesCount: 1,
    image: 'image-3',
    imageV432x230: 'image-3',
    description: '',
    descriptionHtml: '',
    currentUserTodos: {
      __typename: 'ToDo',
      nodes: [],
    },
  },
];

export const moveDesignMutationResponse = {
  data: {
    designManagementMove: {
      designCollection: {
        __typename: 'DesignCollection',
        designs: {
          __typename: 'DesignConnection',
          nodes: [...reorderedDesigns],
        },
      },
      errors: [],
    },
  },
};

export const moveDesignMutationResponseWithErrors = {
  data: {
    designManagementMove: {
      designCollection: {
        designs: {
          nodes: [...reorderedDesigns],
        },
      },
      errors: ['Houston, we have a problem'],
    },
  },
};

export const resolveCommentMutationResponse = {
  discussionToggleResolve: {
    discussion: {
      noteable: {
        id: 'gid://gitlab/DesignManagement::Design/1',
        currentUserTodos: {
          nodes: [],
          __typename: 'TodoConnection',
        },
        __typename: 'Design',
      },
      __typename: 'Discussion',
    },
    errors: [],
    __typename: 'DiscussionToggleResolvePayload',
  },
};

export const getDesignQueryResponse = {
  project: {
    issue: {
      designCollection: {
        designs: {
          nodes: [
            {
              id: 'gid://gitlab/DesignManagement::Design/1',
              currentUserTodos: {
                nodes: [{ id: 'gid://gitlab/Todo::1' }],
              },
            },
          ],
        },
      },
    },
  },
};

export const mockNoteSubmitSuccessMutationResponse = {
  data: {
    createNote: {
      note: {
        id: 'gid://gitlab/DiffNote/468',
        author: {
          id: 'gid://gitlab/User/1',
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          name: 'Administrator',
          username: 'root',
          webUrl: 'http://127.0.0.1:3000/root',
          webPath: '/root',
          __typename: 'UserCore',
        },
        awardEmoji: {
          nodes: [],
        },
        body: 'New comment',
        bodyHtml: "<p data-sourcepos='1:1-1:4' dir='auto'>asdd</p>",
        createdAt: '2023-02-24T06:49:20Z',
        resolved: false,
        position: {
          diffRefs: {
            baseSha: 'f63ae53ed82d8765477c191383e1e6a000c10375',
            startSha: 'f63ae53ed82d8765477c191383e1e6a000c10375',
            headSha: 'f348c652f1a737151fc79047895e695fbe81464c',
            __typename: 'DiffRefs',
          },
          x: 441,
          y: 128,
          height: 152,
          width: 695,
          __typename: 'DiffPosition',
        },
        imported: false,
        userPermissions: {
          adminNote: true,
          repositionNote: true,
          awardEmoji: true,
          __typename: 'NotePermissions',
        },
        discussion: {
          id: 'gid://gitlab/Discussion/6466a72f35b163f3c3e52d7976a09387f2c573e8',
          notes: {
            nodes: [
              {
                id: 'gid://gitlab/DiffNote/459',
                __typename: 'Note',
              },
            ],
            __typename: 'NoteConnection',
          },
          __typename: 'Discussion',
        },
        __typename: 'Note',
      },
      errors: [],
      __typename: 'CreateNotePayload',
    },
  },
};

export const mockNoteSubmitFailureMutationResponse = [
  {
    errors: [
      {
        message:
          'Variable $input of type CreateNoteInput! was provided invalid value for bodyaa (Field is not defined on CreateNoteInput), body (Expected value to not be null)',
        locations: [
          {
            line: 1,
            column: 21,
          },
        ],
        extensions: {
          value: {
            noteableId: 'gid://gitlab/DesignManagement::Design/10',
            discussionId: 'gid://gitlab/Discussion/6466a72f35b163f3c3e52d7976a09387f2c573e8',
            bodyaa: 'df',
          },
          problems: [
            {
              path: ['bodyaa'],
              explanation: 'Field is not defined on CreateNoteInput',
            },
            {
              path: ['body'],
              explanation: 'Expected value to not be null',
            },
          ],
        },
      },
    ],
  },
];

export const mockCreateImageNoteDiffResponse = {
  data: {
    createImageDiffNote: {
      note: {
        author: {
          username: '',
        },
        discussion: {},
      },
    },
  },
};

export const designFactory = ({
  updateDesign = true,
  discussions = {},
  description = 'Test description',
  descriptionHtml = '<p data-sourcepos="1:1-1:16" dir="auto">Test description</p>',
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
  discussions,
  __typename: 'Design',
});

export const designUpdateFactory = (options) => {
  return {
    data: {
      designManagementUpdate: {
        errors: [],
        design: designFactory(options),
      },
      __typename: 'DesignManagementUpdatePayload',
    },
  };
};
