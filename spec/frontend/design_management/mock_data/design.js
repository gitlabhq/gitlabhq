export default {
  id: 'gid::/gitlab/Design/1',
  filename: 'test.jpg',
  fullPath: 'full-design-path',
  image: 'test.jpg',
  updatedAt: '01-01-2019',
  updatedBy: {
    name: 'test',
  },
  issue: {
    id: 'gid::/gitlab/Issue/1',
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
        },
      ],
    },
  },
  discussions: {
    nodes: [
      {
        id: 'discussion-id',
        replyId: 'discussion-reply-id',
        resolved: false,
        notes: {
          nodes: [
            {
              id: 'note-id',
              body: '123',
              author: {
                name: 'Administrator',
                username: 'root',
                webUrl: 'link-to-author',
                avatarUrl: 'link-to-avatar',
              },
            },
          ],
        },
      },
      {
        id: 'discussion-resolved',
        replyId: 'discussion-reply-resolved',
        resolved: true,
        notes: {
          nodes: [
            {
              id: 'note-resolved',
              body: '123',
              author: {
                name: 'Administrator',
                username: 'root',
                webUrl: 'link-to-author',
                avatarUrl: 'link-to-avatar',
              },
            },
          ],
        },
      },
    ],
  },
  diffRefs: {
    headSha: 'headSha',
    baseSha: 'baseSha',
    startSha: 'startSha',
  },
};
