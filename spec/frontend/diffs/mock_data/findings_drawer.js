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
  details: [
    {
      name: 'code_flows',
      type: 'VulnerabilityDetailCodeFlows',
      items: [],
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

export const mockFindingDetails = [
  {
    name: 'code_flows',
    type: 'VulnerabilityDetailCodeFlows',
    items: [
      {
        nodeType: 'SOURCE',
        fileLocation: {
          fileName: 'app/app.py',
          lineStart: 8,
          lineEnd: 8,
        },
      },
      {
        nodeType: 'PROPAGATION',
        fileLocation: {
          fileName: 'app/app.py',
          lineStart: 8,
          lineEnd: 8,
        },
      },
      {
        nodeType: 'SINK',
        fileLocation: {
          fileName: 'app/utils.py',
          lineStart: 5,
          lineEnd: 5,
        },
      },
    ],
  },
];
