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

export const DISCUSSION_1 = {
  id: 'discussion-id-1',
  resolved: false,
  resolvable: true,
  notes: [
    {
      id: 'note-id-1',
      index: 1,
      position: {
        height: 100,
        width: 100,
        x: 10,
        y: 15,
      },
      author: mockAuthor,
      awardEmoji: mockAwardEmoji,
      createdAt: '2020-05-08T07:10:45Z',
      imported: false,
      userPermissions: {
        repositionNote: true,
        awardEmoji: true,
      },
      resolved: false,
    },
    {
      id: 'note-id-3',
      index: 3,
      position: {
        height: 50,
        width: 50,
        x: 25,
        y: 25,
      },
      author: {
        id: 'gid://gitlab/User/2',
        name: 'Mary',
        webUrl: 'link-to-mary-profile',
      },
      awardEmoji: mockAwardEmoji,
      createdAt: '2020-05-08T07:10:45Z',
      imported: false,
      userPermissions: {
        adminNote: true,
        awardEmoji: true,
      },
      resolved: false,
    },
  ],
};

const DISCUSSION_2 = {
  id: 'discussion-id-2',
  notes: {
    nodes: [
      {
        id: 'note-id-2',
        index: 2,
        position: {
          height: 50,
          width: 50,
          x: 25,
          y: 25,
        },
        author: {
          name: 'Mary',
          webUrl: 'link-to-mary-profile',
        },
        awardEmoji: mockAwardEmoji,
        createdAt: '2020-05-08T07:10:45Z',
        imported: false,
        userPermissions: {
          adminNote: true,
          awardEmoji: true,
        },
        resolved: true,
      },
    ],
  },
};

export const DISCUSSION_3 = {
  id: 'discussion-id-3',
  notes: {
    nodes: [
      {
        id: 'note-id-4',
        index: 2,
        position: {
          height: 50,
          width: 50,
          x: 35,
          y: 25,
        },
        author: {
          name: 'Smith',
          webUrl: 'link-to-smith-profile',
        },
        awardEmoji: mockAwardEmoji,
        createdAt: '2020-05-09T07:10:45Z',
        imported: false,
        userPermissions: {
          adminNote: true,
          awardEmoji: true,
        },
        resolved: false,
      },
    ],
  },
};

export default [
  {
    ...DISCUSSION_1.notes[0],
    discussion: {
      id: DISCUSSION_1.id,
      notes: {
        nodes: DISCUSSION_1.notes,
      },
    },
  },
  {
    ...DISCUSSION_2.notes.nodes[0],
    discussion: DISCUSSION_2,
  },
];
