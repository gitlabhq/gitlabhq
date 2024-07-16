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
      name: 'Method `long_if` has a Cognitive Complexity of 10 (exceeds 5 allowed). Consider refactoring.',
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
