export default [
  {
    id: 'note-id-1',
    index: 1,
    position: {
      height: 100,
      width: 100,
      x: 10,
      y: 15,
    },
    author: {
      name: 'John',
      webUrl: 'link-to-john-profile',
    },
    createdAt: '2020-05-08T07:10:45Z',
    userPermissions: {
      adminNote: true,
    },
    discussion: {
      id: 'discussion-id-1',
    },
    resolved: false,
  },
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
    createdAt: '2020-05-08T07:10:45Z',
    userPermissions: {
      adminNote: true,
    },
    discussion: {
      id: 'discussion-id-2',
    },
    resolved: true,
  },
];
