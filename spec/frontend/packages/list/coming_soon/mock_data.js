export const fakeIssues = [
  {
    id: 1,
    iid: 1,
    title: 'issue one',
    webUrl: 'foo',
  },
  {
    id: 2,
    iid: 2,
    title: 'issue two',
    labels: [{ title: 'Accepting merge requests', color: '#69d100' }],
    milestone: {
      title: '12.10',
    },
    webUrl: 'foo',
  },
  {
    id: 3,
    iid: 3,
    title: 'issue three',
    labels: [{ title: 'workflow::In dev', color: '#428bca' }],
    webUrl: 'foo',
  },
  {
    id: 4,
    iid: 4,
    title: 'issue four',
    labels: [
      { title: 'Accepting merge requests', color: '#69d100' },
      { title: 'workflow::In dev', color: '#428bca' },
    ],
    webUrl: 'foo',
  },
];

export const asGraphQLResponse = {
  project: {
    issues: {
      nodes: fakeIssues.map(x => ({
        ...x,
        labels: {
          nodes: x.labels,
        },
      })),
    },
  },
};

export const asViewModel = [
  {
    ...fakeIssues[0],
    labels: [],
  },
  {
    ...fakeIssues[1],
    labels: [
      {
        title: 'Accepting merge requests',
        color: '#69d100',
        scoped: false,
      },
    ],
  },
  {
    ...fakeIssues[2],
    labels: [
      {
        title: 'workflow::In dev',
        color: '#428bca',
        scoped: true,
      },
    ],
  },
  {
    ...fakeIssues[3],
    labels: [
      {
        title: 'workflow::In dev',
        color: '#428bca',
        scoped: true,
      },
      {
        title: 'Accepting merge requests',
        color: '#69d100',
        scoped: false,
      },
    ],
  },
];
