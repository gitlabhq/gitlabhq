export default {
  __typename: 'Design',
  id: 'gid:/gitlab/Design/1',
  event: 'NONE',
  notesCount: 0,
  filename: 'test.jpg',
  fullPath: 'full-design-path',
  image: 'test.jpg',
  imageV432x230: 'test.jpg',
  imported: true,
  currentUserTodos: null,
  description: 'Test description',
  descriptionHtml: 'Test description',
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
          id: 'gid://gitlab/User/1',
          name: 'Administrator',
          username: 'root',
          webUrl: 'link-to-author',
          avatarUrl: 'link-to-avatar',
        },
      ],
    },
    userPermissions: {
      createDesign: true,
      updateDesign: true,
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
                id: 'gid://gitlab/User/1',
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
                id: 'gid://gitlab/User/1',
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
