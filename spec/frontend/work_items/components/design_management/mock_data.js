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
    nodes: [
      {
        id: 'discussion-id',
        replyId: 'discussion-reply-id',
        notes: {
          nodes: [],
          __typename: 'NoteConnection',
        },
      },
      {
        id: 'discussion-resolved',
        replyId: 'discussion-reply-resolved',
        notes: {
          nodes: [],
          __typename: 'NoteConnection',
        },
      },
    ],
    __typename: 'DiscussionConnection',
  },
  diffRefs: {
    baseSha: 'f63ae53ed82d8765477c191383e1e6a000c10375',
    startSha: 'f63ae53ed82d8765477c191383e1e6a000c10375',
    headSha: 'f348c652f1a737151fc79047895e695fbe81464c',
    __typename: 'DiffRefs',
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
  description: 'Description test 2',
  descriptionHtml: '<p>Description test 2</p>',
  image: 'raw_image_1',
  imageV432x230: 'resized_image_v432x230_1',
  fullPath: 'designs/issue-2/Screenshot_from_2024-03-28_10-24-44.png',
  currentUserTodos: {
    nodes: [],
    __typename: 'TodoConnection',
  },
  discussions: {
    nodes: [],
    __typename: 'DiscussionConnection',
  },
  diffRefs: {
    baseSha: 'f63ae53ed82d8765477c191383e1e6a000c10375',
    startSha: 'f63ae53ed82d8765477c191383e1e6a000c10375',
    headSha: 'f348c652f1a737151fc79047895e695fbe81464c',
    __typename: 'DiffRefs',
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
    designManagement: {
      designAtVersion: {
        id: 'gid://gitlab/DesignManagement::DesignAtVersion/1',
        event: 'NONE',
        image: 'raw_image_1',
        imageV432x230: 'resized_image_v432x230_1',
        design: mockDesign,
        version: mockAllVersions[0],
      },
      __typename: 'DesignManagement',
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

export const mockMoveDesignMutationResponse = {
  data: {
    designManagementMove: {
      designCollection: {
        __typename: 'DesignCollection',
        designs: {
          __typename: 'DesignConnection',
          nodes: [mockDesign2, mockDesign],
        },
      },
      errors: [],
    },
  },
};

export const mockMoveDesignMutationErrorResponse = {
  data: {
    designManagementMove: {
      designCollection: {
        designs: {
          nodes: [mockDesign2, mockDesign],
        },
      },
      errors: ['Something went wrong when reordering designs. Please try again'],
    },
  },
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

export const mockCreateImageNoteDiffResponse = {
  data: {
    createImageDiffNote: {
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
      __typename: 'CreateImageDiffNotePayload',
    },
  },
};

export const mockResolveDiscussionMutationResponse = {
  data: {
    discussionToggleResolve: {
      discussion: {
        id: 'gid://gitlab/Discussion/c4be5bec43a737e0966dbc4c040b1517e7febfa9',
        notes: {
          nodes: [
            {
              id: 'gid://gitlab/DiscussionNote/2506',
              body: 'test3',
              bodyHtml: '<p data-sourcepos="1:1-1:5" dir="auto">test3</p>',
              system: false,
              internal: false,
              systemNoteIconName: null,
              createdAt: '2024-07-19T05:52:01Z',
              lastEditedAt: '2024-07-26T10:06:02Z',
              url: 'http://127.0.0.1:3000/flightjs/Flight/-/issues/134#note_2506',
              authorIsContributor: false,
              maxAccessLevelOfAuthor: 'Owner',
              lastEditedBy: null,
              externalAuthor: null,
              discussion: {
                id: 'gid://gitlab/Discussion/c4be5bec43a737e0966dbc4c040b1517e7febfa9',
                resolved: true,
                resolvable: true,
                resolvedBy: {
                  id: 'gid://gitlab/User/1',
                  name: 'Administrator',
                  __typename: 'UserCore',
                },
                __typename: 'Discussion',
              },
              author: {
                id: 'gid://gitlab/User/1',
                avatarUrl:
                  'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
                name: 'Administrator',
                username: 'root',
                webUrl: 'http://127.0.0.1:3000/root',
                webPath: '/root',
                __typename: 'UserCore',
              },
              awardEmoji: {
                nodes: [],
                __typename: 'AwardEmojiConnection',
              },
              userPermissions: {
                adminNote: true,
                awardEmoji: true,
                readNote: true,
                createNote: true,
                resolveNote: true,
                repositionNote: true,
                __typename: 'NotePermissions',
              },
              systemNoteMetadata: null,
              __typename: 'Note',
            },
            {
              id: 'gid://gitlab/DiscussionNote/2539',
              body: 'comment',
              bodyHtml: '<p data-sourcepos="1:1-1:7" dir="auto">comment</p>',
              system: false,
              internal: false,
              systemNoteIconName: null,
              createdAt: '2024-07-23T05:07:46Z',
              lastEditedAt: '2024-07-26T10:06:02Z',
              url: 'http://127.0.0.1:3000/flightjs/Flight/-/issues/134#note_2539',
              authorIsContributor: false,
              maxAccessLevelOfAuthor: 'Owner',
              lastEditedBy: null,
              externalAuthor: null,
              discussion: {
                id: 'gid://gitlab/Discussion/c4be5bec43a737e0966dbc4c040b1517e7febfa9',
                resolved: true,
                resolvable: true,
                resolvedBy: {
                  id: 'gid://gitlab/User/1',
                  name: 'Administrator',
                  __typename: 'UserCore',
                },
                __typename: 'Discussion',
              },
              author: {
                id: 'gid://gitlab/User/1',
                avatarUrl:
                  'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
                name: 'Administrator',
                username: 'root',
                webUrl: 'http://127.0.0.1:3000/root',
                webPath: '/root',
                __typename: 'UserCore',
              },
              awardEmoji: {
                nodes: [],
                __typename: 'AwardEmojiConnection',
              },
              userPermissions: {
                adminNote: true,
                awardEmoji: true,
                readNote: true,
                createNote: true,
                resolveNote: true,
                repositionNote: true,
                __typename: 'NotePermissions',
              },
              systemNoteMetadata: null,
              __typename: 'Note',
            },
          ],
          __typename: 'NoteConnection',
        },
        __typename: 'Discussion',
      },
      errors: [],
      __typename: 'DiscussionToggleResolvePayload',
    },
  },
};

export const getAwardEmojiResponse = (toggledOn) => {
  return {
    data: {
      awardEmojiToggle: {
        errors: [],
        toggledOn,
        __typename: 'AwardEmojiTogglePayload',
      },
    },
  };
};

export const mockRepositionImageNoteDiffResponse = {
  data: {
    __typename: 'Mutation',
    repositionImageDiffNote: {
      __typename: 'RepositionImageDiffNotePayload',
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
    },
  },
};
