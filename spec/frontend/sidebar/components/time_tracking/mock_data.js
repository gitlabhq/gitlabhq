export const timelogToRemoveId = 'gid://gitlab/Timelog/18';

export const getIssueTimelogsQueryResponse = {
  data: {
    issuable: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/148',
      title:
        'Est perferendis dicta expedita ipsum adipisci laudantium omnis consequatur consequatur et.',
      timelogs: {
        nodes: [
          {
            __typename: 'Timelog',
            id: timelogToRemoveId,
            timeSpent: 14400,
            user: {
              id: 'user-1',
              name: 'John Doe18',
              __typename: 'UserCore',
            },
            spentAt: '2020-05-01T00:00:00Z',
            note: {
              id: 'note-1',
              body: 'A note',
              __typename: 'Note',
            },
            summary: 'A summary',
            userPermissions: {
              adminTimelog: true,
              __typename: 'TimelogPermissions',
            },
          },
          {
            __typename: 'Timelog',
            id: 'gid://gitlab/Timelog/20',
            timeSpent: 1800,
            user: {
              id: 'user-2',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T13:19:01Z',
            note: null,
            summary: 'A summary',
            userPermissions: {
              adminTimelog: false,
              __typename: 'TimelogPermissions',
            },
          },
          {
            __typename: 'Timelog',
            id: 'gid://gitlab/Timelog/25',
            timeSpent: 14400,
            user: {
              id: 'user-2',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-01T00:00:00Z',
            note: {
              id: 'note-2',
              body: 'A note',
              __typename: 'Note',
            },
            summary: null,
            userPermissions: {
              adminTimelog: false,
              __typename: 'TimelogPermissions',
            },
          },
        ],
        __typename: 'TimelogConnection',
      },
    },
  },
};

export const getMrTimelogsQueryResponse = {
  data: {
    issuable: {
      __typename: 'MergeRequest',
      id: 'gid://gitlab/MergeRequest/29',
      title: 'Esse amet perspiciatis voluptas et sed praesentium debitis repellat.',
      timelogs: {
        nodes: [
          {
            __typename: 'Timelog',
            id: 'gid://gitlab/Timelog/13',
            timeSpent: 1800,
            user: {
              id: 'user-1',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T14:44:55Z',
            note: {
              id: 'note-1',
              body: 'Thirty minutes!',
              __typename: 'Note',
            },
            summary: null,
            userPermissions: {
              adminTimelog: true,
              __typename: 'TimelogPermissions',
            },
          },
          {
            __typename: 'Timelog',
            id: 'gid://gitlab/Timelog/22',
            timeSpent: 3600,
            user: {
              id: 'user-1',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T14:44:39Z',
            note: null,
            summary: null,
            userPermissions: {
              adminTimelog: true,
              __typename: 'TimelogPermissions',
            },
          },
          {
            __typename: 'Timelog',
            id: 'gid://gitlab/Timelog/64',
            timeSpent: 300,
            user: {
              id: 'user-1',
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-03-10T00:00:00Z',
            note: {
              id: 'note-2',
              body: 'A note with some time',
              __typename: 'Note',
            },
            summary: null,
            userPermissions: {
              adminTimelog: true,
              __typename: 'TimelogPermissions',
            },
          },
        ],
        __typename: 'TimelogConnection',
      },
    },
  },
};

export const deleteTimelogMutationResponse = {
  data: {
    timelogDelete: {
      errors: [],
      timelog: {
        id: 'gid://gitlab/Issue/148',
        issue: {},
        mergeRequest: {},
      },
    },
  },
};
