import { mockAuthor, mockAwardEmoji } from './apollo_mock';

export default {
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
