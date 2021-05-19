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
            timeSpent: 14400,
            user: {
              name: 'John Doe18',
              __typename: 'UserCore',
            },
            spentAt: '2020-05-01T00:00:00Z',
            note: {
              body: 'I paired with @root on this last week.',
              __typename: 'Note',
            },
          },
          {
            __typename: 'Timelog',
            timeSpent: 1800,
            user: {
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T13:19:01Z',
            note: null,
          },
          {
            __typename: 'Timelog',
            timeSpent: 14400,
            user: {
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-01T00:00:00Z',
            note: {
              body: 'I did some work on this last week.',
              __typename: 'Note',
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
            timeSpent: 1800,
            user: {
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T14:44:55Z',
            note: {
              body: 'Thirty minutes!',
              __typename: 'Note',
            },
          },
          {
            __typename: 'Timelog',
            timeSpent: 3600,
            user: {
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-05-07T14:44:39Z',
            note: null,
          },
          {
            __typename: 'Timelog',
            timeSpent: 300,
            user: {
              name: 'Administrator',
              __typename: 'UserCore',
            },
            spentAt: '2021-03-10T00:00:00Z',
            note: {
              body: 'A note with some time',
              __typename: 'Note',
            },
          },
        ],
        __typename: 'TimelogConnection',
      },
    },
  },
};
