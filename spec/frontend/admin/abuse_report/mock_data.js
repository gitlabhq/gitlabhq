export const mockAbuseReport = {
  user: {
    username: 'spamuser417',
    name: 'Sp4m User',
    createdAt: '2023-03-29T09:30:23.885Z',
    email: 'sp4m@spam.com',
    lastActivityOn: '2023-04-02',
    avatarUrl: 'https://www.gravatar.com/avatar/a2579caffc69ea5d7606f9dd9d8504ba?s=80&d=identicon',
    path: '/spamuser417',
    adminPath: '/admin/users/spamuser417',
    plan: 'Free',
    verificationState: { email: true, phone: true, creditCard: true },
    creditCard: {
      name: 'S. User',
      similarRecordsCount: 2,
      cardMatchesLink: '/admin/users/spamuser417/card_match',
    },
    phoneNumber: {
      similarRecordsCount: 2,
      phoneMatchesLink: '/admin/users/spamuser417/phone_match',
    },
    pastClosedReports: [
      {
        category: 'offensive',
        createdAt: '2023-02-28T10:09:54.982Z',
        reportPath: '/admin/abuse_reports/29',
      },
      {
        category: 'crypto',
        createdAt: '2023-03-31T11:57:11.849Z',
        reportPath: '/admin/abuse_reports/31',
      },
    ],
    mostUsedIp: null,
    lastSignInIp: '::1',
    snippetsCount: 0,
    groupsCount: 0,
    notesCount: 6,
    similarOpenReports: [
      {
        status: 'open',
        message: 'This is obvious spam',
        reportedAt: '2023-03-29T09:39:50.502Z',
        category: 'spam',
        type: 'issue',
        content: '',
        screenshot: null,
        reporter: {
          username: 'reporter 2',
          name: 'Another Reporter',
          avatarUrl: 'https://www.gravatar.com/avatar/anotherreporter',
          path: '/reporter-2',
        },
        updatePath: '/admin/abuse_reports/28',
      },
    ],
  },
  report: {
    globalId: 'gid://gitlab/AbuseReport/1',
    status: 'open',
    message: 'This is obvious spam',
    reportedAt: '2023-03-29T09:39:50.502Z',
    category: 'spam',
    type: 'comment',
    content:
      '<p data-sourcepos="1:1-1:772" dir="auto">Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON <a href="http://www.farmers.com" rel="nofollow noreferrer noopener" target="_blank">www.farmers.com</a> | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON <a href="http://www.farmers.com" rel="nofollow noreferrer noopener" target="_blank">www.farmers.com</a> | SHOP CATALOGUE ... 50% off Kids\' Underwear by Hanes ... BUY 1 GET 1 HALF PRICE on Women\'s Clothing by Whistle, Ella Clothing Farmers Toy Sale ON NOW | SHOP CATALOGUE ... 50% off Kids\' Underwear by.</p>',
    url: 'http://localhost:3000/spamuser417/project/-/merge_requests/1#note_1375',
    screenshot:
      '/uploads/-/system/abuse_report/screenshot/27/Screenshot_2023-03-30_at_16.56.37.png',
    updatePath: '/admin/abuse_reports/27',
    moderateUserPath: '/admin/abuse_reports/27/moderate_user',
    reporter: {
      username: 'reporter',
      name: 'R Porter',
      avatarUrl:
        'https://www.gravatar.com/avatar/a2579caffc69ea5d7606f9dd9d8504ba?s=80&d=identicon',
      path: '/reporter',
    },
  },
};

export const mockLabel1 = {
  id: 'gid://gitlab/AntiAbuse::Reports::Label/1',
  title: 'Uno',
  color: '#F0AD4E',
  textColor: '#FFFFFF',
  description: null,
};

export const mockLabel2 = {
  id: 'gid://gitlab/AntiAbuse::Reports::Label/2',
  title: 'Dos',
  color: '#F0AD4E',
  textColor: '#FFFFFF',
  description: null,
};

export const mockLabelsQueryResponse = {
  data: {
    labels: {
      nodes: [mockLabel1, mockLabel2],
      __typename: 'LabelConnection',
    },
  },
};

export const mockReportQueryResponse = {
  data: {
    abuseReport: {
      id: 'gid://gitlab/AbuseReport/1',
      labels: {
        nodes: [mockLabel1],
        __typename: 'LabelConnection',
      },
      discussions: {
        nodes: [],
      },
      __typename: 'AbuseReport',
    },
  },
};

export const mockCreateLabelResponse = {
  data: {
    labelCreate: {
      label: {
        id: 'gid://gitlab/AntiAbuse::Reports::Label/1',
        color: '#ed9121',
        description: null,
        title: 'abuse report label',
        textColor: '#FFFFFF',
        __typename: 'Label',
      },
      errors: [],
      __typename: 'AbuseReportLabelCreatePayload',
    },
  },
};

export const mockDiscussionWithNoReplies = [
  {
    id: 'gid://gitlab/Note/1',
    body: 'Comment 1',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:9" dir="auto"\u003eComment 1\u003c/p\u003e',
    createdAt: '2023-10-19T06:11:13Z',
    lastEditedAt: null,
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_1',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    userPermissions: {
      resolveNote: true,
      __typename: 'NotePermissions',
    },
    discussion: {
      id: 'gid://gitlab/Discussion/055af96ab917175219aec8739c911277b18ea41d',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/Note/1',
            __typename: 'Note',
          },
        ],
        __typename: 'NoteConnection',
      },
      __typename: 'Discussion',
    },
    __typename: 'Note',
  },
];
export const mockDiscussionWithReplies = [
  {
    id: 'gid://gitlab/DiscussionNote/2',
    body: 'Comment 2',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:9" dir="auto"\u003eComment 2\u003c/p\u003e',
    createdAt: '2023-10-20T07:47:21Z',
    lastEditedAt: '2023-10-20T07:47:42Z',
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_2',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    userPermissions: {
      resolveNote: true,
      __typename: 'NotePermissions',
    },
    discussion: {
      id: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/DiscussionNote/2',
            __typename: 'Note',
          },
          {
            id: 'gid://gitlab/DiscussionNote/3',
            __typename: 'Note',
          },
          {
            id: 'gid://gitlab/DiscussionNote/4',
            __typename: 'Note',
          },
        ],
        __typename: 'NoteConnection',
      },
      __typename: 'Discussion',
    },
    __typename: 'Note',
  },
  {
    id: 'gid://gitlab/DiscussionNote/3',
    body: 'Reply comment 1',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:15" dir="auto"\u003eReply comment 1\u003c/p\u003e',
    createdAt: '2023-10-20T07:47:42Z',
    lastEditedAt: '2023-10-20T07:47:42Z',
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_3',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    userPermissions: {
      resolveNote: true,
      __typename: 'NotePermissions',
    },
    discussion: {
      id: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/DiscussionNote/2',
            __typename: 'Note',
          },
          {
            id: 'gid://gitlab/DiscussionNote/3',
            __typename: 'Note',
          },
          {
            id: 'gid://gitlab/DiscussionNote/4',
            __typename: 'Note',
          },
        ],
        __typename: 'NoteConnection',
      },
      __typename: 'Discussion',
    },
    __typename: 'Note',
  },
  {
    id: 'gid://gitlab/DiscussionNote/4',
    body: 'Reply comment 2',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:15" dir="auto"\u003eReply comment 2\u003c/p\u003e',
    createdAt: '2023-10-20T08:26:51Z',
    lastEditedAt: '2023-10-20T08:26:51Z',
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_4',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    userPermissions: {
      resolveNote: true,
      __typename: 'NotePermissions',
    },
    discussion: {
      id: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/DiscussionNote/2',
            __typename: 'Note',
          },
          {
            id: 'gid://gitlab/DiscussionNote/3',
            __typename: 'Note',
          },
          {
            id: 'gid://gitlab/DiscussionNote/4',
            __typename: 'Note',
          },
        ],
        __typename: 'NoteConnection',
      },
      __typename: 'Discussion',
    },
    __typename: 'Note',
  },
];

export const mockAbuseReportDiscussionWithNoReplies = [
  {
    id: 'gid://gitlab/AntiAbuse::Reports::Note/1',
    body: 'Comment 1',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:9" dir="auto"\u003eComment 1\u003c/p\u003e',
    createdAt: '2023-10-19T06:11:13Z',
    lastEditedAt: null,
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_1',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    discussion: {
      id: 'gid://gitlab/Discussion/055af96ab917175219aec8739c911277b18ea41d',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/AntiAbuse::Reports::Note/1',
            __typename: 'Note',
          },
        ],
        __typename: 'AbuseReportNoteConnection',
      },
      __typename: 'AbuseReportDiscussion',
    },
    __typename: 'AbuseReportNote',
  },
];
export const mockAbuseReportDiscussionWithReplies = [
  {
    id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/2',
    body: 'Comment 2',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:9" dir="auto"\u003eComment 2\u003c/p\u003e',
    createdAt: '2023-10-20T07:47:21Z',
    lastEditedAt: '2023-10-20T07:47:42Z',
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_2',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    discussion: {
      id: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/2',
            __typename: 'AbuseReportNote',
          },
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/3',
            __typename: 'AbuseReportNote',
          },
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/4',
            __typename: 'AbuseReportNote',
          },
        ],
        __typename: 'AbuseReportNoteConnection',
      },
      __typename: 'AbuseReportDiscussion',
    },
    __typename: 'AbuseReportNote',
  },
  {
    id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/3',
    body: 'Reply comment 1',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:15" dir="auto"\u003eReply comment 1\u003c/p\u003e',
    createdAt: '2023-10-20T07:47:42Z',
    lastEditedAt: '2023-10-20T07:47:42Z',
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_3',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    discussion: {
      id: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/2',
            __typename: 'AbuseReportNote',
          },
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/3',
            __typename: 'AbuseReportNote',
          },
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/4',
            __typename: 'AbuseReportNote',
          },
        ],
        __typename: 'AbuseReportNoteConnection',
      },
      __typename: 'AbuseReportDiscussion',
    },
    __typename: 'AbuseReportNote',
  },
  {
    id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/4',
    body: 'Reply comment 2',
    bodyHtml: '\u003cp data-sourcepos="1:1-1:15" dir="auto"\u003eReply comment 2\u003c/p\u003e',
    createdAt: '2023-10-20T08:26:51Z',
    lastEditedAt: '2023-10-20T08:26:51Z',
    url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_4',
    resolved: false,
    author: {
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://127.0.0.1:3000/root',
      webPath: '/root',
      __typename: 'UserCore',
    },
    lastEditedBy: null,
    discussion: {
      id: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
      notes: {
        nodes: [
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/2',
            __typename: 'AbuseReportNote',
          },
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/3',
            __typename: 'AbuseReportNote',
          },
          {
            id: 'gid://gitlab/AntiAbuse::Reports::DiscussionNote/4',
            __typename: 'AbuseReportNote',
          },
        ],
        __typename: 'AbuseReportNoteConnection',
      },
      __typename: 'AbuseReportDiscussion',
    },
    __typename: 'AbuseReportNote',
  },
];

export const mockNotesByIdResponse = {
  data: {
    abuseReport: {
      id: 'gid://gitlab/AbuseReport/1',
      discussions: {
        nodes: [
          {
            id: 'gid://gitlab/Discussion/055af96ab917175219aec8739c911277b18ea41d',
            replyId:
              'gid://gitlab/AntiAbuse::Reports::IndividualNoteDiscussion/055af96ab917175219aec8739c911277b18ea41d',
            notes: {
              nodes: mockAbuseReportDiscussionWithNoReplies,
              __typename: 'AbuseReportNoteConnection',
            },
          },
          {
            id: 'gid://gitlab/Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
            replyId:
              'gid://gitlab/AntiAbuse::Reports::Discussion/9c7228e06fb0339a3d1440fcda960acfd8baa43a',
            notes: {
              nodes: mockAbuseReportDiscussionWithReplies,
              __typename: 'AbuseReportNoteConnection',
            },
          },
        ],
        __typename: 'AbuseReportDiscussionConnection',
      },
      __typename: 'AbuseReport',
    },
  },
};

export const createAbuseReportNoteResponse = {
  data: {
    createAbuseReportNote: {
      note: {
        id: 'gid://gitlab/AntiAbuse::Reports::Note/6',
        discussion: {
          id: 'gid://gitlab/Discussion/90ca230051611e6e1676c50ba7178e0baeabd98d',
          notes: {
            nodes: [
              {
                id: 'gid://gitlab/AntiAbuse::Reports::Note/6',
                body: 'Another comment',
                bodyHtml: '<p data-sourcepos="1:1-1:15" dir="auto">Another comment</p>',
                createdAt: '2023-11-02T02:45:46Z',
                lastEditedAt: null,
                url: 'http://127.0.0.1:3000/admin/abuse_reports/20#note_6',
                resolved: false,
                author: {
                  id: 'gid://gitlab/User/1',
                  avatarUrl:
                    'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                  name: 'Administrator',
                  username: 'root',
                  webUrl: 'http://127.0.0.1:3000/root',
                  webPath: '/root',
                },
                lastEditedBy: null,
                discussion: {
                  id: 'gid://gitlab/Discussion/90ca230051611e6e1676c50ba7178e0baeabd98d',
                  notes: {
                    nodes: [
                      {
                        id: 'gid://gitlab/AntiAbuse::Reports::Note/6',
                      },
                    ],
                  },
                },
              },
            ],
          },
        },
      },
      errors: [],
    },
  },
};

export const editAbuseReportNoteResponse = {
  data: {
    updateAbuseReportNote: {
      errors: [],
      note: {
        id: 'gid://gitlab/Note/1',
        body: 'Updated comment',
        bodyHtml: '<p data-sourcepos="1:1-1:15" dir="auto">Updated comment</p>',
        createdAt: '2023-10-20T07:47:42Z',
        lastEditedAt: '2023-10-20T07:47:42Z',
        url: 'http://127.0.0.1:3000/admin/abuse_reports/1#note_1',
        resolved: false,
        author: {
          id: 'gid://gitlab/User/1',
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
          name: 'Administrator',
          username: 'root',
          webUrl: 'http://127.0.0.1:3000/root',
          webPath: '/root',
          __typename: 'UserCore',
        },
        lastEditedBy: 'root',
        userPermissions: {
          resolveNote: true,
          __typename: 'NotePermissions',
        },
      },
    },
  },
};

export const editAbuseReportNoteResponseWithErrors = {
  data: {
    updateAbuseReportNote: {
      errors: ['foo', 'bar'],
      note: null,
    },
  },
};
