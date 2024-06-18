import { mockAwardEmoji } from './apollo_mock';
import DISCUSSION_1 from './discussion';

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
