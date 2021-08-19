export const devopsScoreTableHeaders = [
  {
    index: 0,
    label: '',
  },
  {
    index: 1,
    label: 'Your usage',
  },
  {
    index: 2,
    label: 'Leader usage',
  },
  {
    index: 3,
    label: 'Score',
  },
];

export const devopsScoreMetricsData = {
  createdAt: '2020-06-29 08:16',
  cards: [
    {
      title: 'Issues created per active user',
      usage: '3.2',
      leadInstance: '10.2',
      score: '0',
      scoreLevel: {
        label: 'Low',
        variant: 'muted',
      },
    },
  ],
  averageScore: {
    value: '10',
    scoreLevel: {
      label: 'High',
      icon: 'check-circle',
      variant: 'success',
    },
  },
};

export const devopsReportDocsPath = 'docs-path';

export const noDataImagePath = 'image-path';

export const devopsScoreIntroImagePath = 'image-path';
