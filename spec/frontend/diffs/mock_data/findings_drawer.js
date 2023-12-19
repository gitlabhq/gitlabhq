export const mockFindingDismissed = {
  title: 'mockedtitle',
  state: 'dismissed',
  scale: 'sast',
  line: 7,
  description: 'fakedesc',
  severity: 'low',
  engineName: 'testengine name',
  categories: ['testcategory 1', 'testcategory 2'],
  content: {
    body: 'Duplicated Code Duplicated code',
  },
  webUrl: {},
  identifiers: [
    {
      __typename: 'VulnerabilityIdentifier',
      externalId: 'eslint.detect-disable-mustache-escape',
      externalType: 'semgrep_id',
      name: 'eslint.detect-disable-mustache-escape',
      url: 'https://semgrep.dev/r/gitlab.eslint.detect-disable-mustache-escape',
    },
  ],
};

export const mockFindingDetected = {
  ...mockFindingDismissed,
  state: 'detected',
};

export const mockProject = {
  nameWithNamespace: 'testname',
  fullPath: 'testpath',
};

export const mockFindingsMultiple = [
  {
    ...mockFindingDismissed,
    title: 'Finding 1',
    severity: 'critical',
    engineName: 'Engine 1',
    identifiers: [
      {
        ...mockFindingDismissed.identifiers[0],
        name: 'identifier 1',
        url: 'https://example.com/identifier1',
      },
    ],
  },
  {
    ...mockFindingDetected,
    title: 'Finding 2',
    severity: 'medium',
    engineName: 'Engine 2',
    identifiers: [
      {
        ...mockFindingDetected.identifiers[0],
        name: 'identifier 2',
        url: 'https://example.com/identifier2',
      },
    ],
  },
  {
    ...mockFindingDetected,
    title: 'Finding 3',
    severity: 'medium',
    engineName: 'Engine 3',
    identifiers: [
      {
        ...mockFindingDetected.identifiers[0],
        name: 'identifier 3',
        url: 'https://example.com/identifier3',
      },
    ],
  },
];
