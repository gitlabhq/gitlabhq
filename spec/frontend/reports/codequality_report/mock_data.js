export const headIssues = [
  {
    check_name: 'Rubocop/Lint/UselessAssignment',
    description: 'Insecure Dependency',
    location: {
      path: 'lib/six.rb',
      lines: {
        begin: 6,
        end: 7,
      },
    },
    fingerprint: 'e879dd9bbc0953cad5037cde7ff0f627',
  },
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 22,
        end: 22,
      },
    },
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
  },
];

export const mockParsedHeadIssues = [
  {
    ...headIssues[1],
    name: 'Insecure Dependency',
    path: 'lib/six.rb',
    urlPath: 'headPath/lib/six.rb#L6',
    line: 6,
  },
];

export const baseIssues = [
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 22,
        end: 22,
      },
    },
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
  },
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 21,
        end: 21,
      },
    },
    fingerprint: 'ca2354534dee94ae60ba2f54e3857c50e5',
  },
];

export const mockParsedBaseIssues = [
  {
    ...baseIssues[1],
    name: 'Insecure Dependency',
    path: 'Gemfile.lock',
    line: 21,
    urlPath: 'basePath/Gemfile.lock#L21',
  },
];

export const issueDiff = [
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
    line: 6,
    location: { lines: { begin: 22, end: 22 }, path: 'Gemfile.lock' },
    name: 'Insecure Dependency',
    path: 'lib/six.rb',
    urlPath: 'headPath/lib/six.rb#L6',
  },
];

export const reportIssues = {
  status: 'failed',
  new_errors: [
    {
      description:
        'Method `long_if` has a Cognitive Complexity of 10 (exceeds 5 allowed). Consider refactoring.',
      severity: 'minor',
      file_path: 'codequality.rb',
      line: 5,
    },
  ],
  resolved_errors: [
    {
      description: 'Insecure Dependency',
      severity: 'major',
      file_path: 'lib/six.rb',
      line: 22,
    },
  ],
  existing_errors: [],
  summary: { total: 3, resolved: 0, errored: 3 },
};

export const parsedReportIssues = {
  newIssues: [
    {
      description:
        'Method `long_if` has a Cognitive Complexity of 10 (exceeds 5 allowed). Consider refactoring.',
      file_path: 'codequality.rb',
      line: 5,
      name:
        'Method `long_if` has a Cognitive Complexity of 10 (exceeds 5 allowed). Consider refactoring.',
      path: 'codequality.rb',
      severity: 'minor',
      urlPath: 'null/codequality.rb#L5',
    },
  ],
  resolvedIssues: [
    {
      description: 'Insecure Dependency',
      file_path: 'lib/six.rb',
      line: 22,
      name: 'Insecure Dependency',
      path: 'lib/six.rb',
      severity: 'major',
      urlPath: 'null/lib/six.rb#L22',
    },
  ],
};
