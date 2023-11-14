export const mockFinding = {
  title: 'mockedtitle',
  state: 'detected',
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

export const mockProject = {
  nameWithNamespace: 'testname',
  fullPath: 'testpath',
};
