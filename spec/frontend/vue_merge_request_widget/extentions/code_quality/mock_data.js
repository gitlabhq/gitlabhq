export const codeQualityResponseNewErrors = {
  status: 'failed',
  new_errors: [
    {
      description: "Parsing error: 'return' outside of function",
      severity: 'minor',
      file_path: 'index.js',
      line: 12,
    },
    {
      description: 'TODO found',
      severity: 'minor',
      file_path: '.gitlab-ci.yml',
      line: 73,
    },
  ],
  resolved_errors: [],
  existing_errors: [],
  summary: {
    total: 12235,
    resolved: 0,
    errored: 12235,
  },
};

export const codeQualityResponseResolvedErrors = {
  status: 'success',
  new_errors: [],
  resolved_errors: [
    {
      description: "Parsing error: 'return' outside of function",
      severity: 'minor',
      file_path: 'index.js',
      line: 12,
    },
    {
      description: 'TODO found',
      severity: 'minor',
      file_path: '.gitlab-ci.yml',
      line: 73,
    },
  ],
  existing_errors: [],
  summary: {
    total: 12235,
    resolved: 0,
    errored: 12235,
  },
};

export const codeQualityResponseResolvedAndNewErrors = {
  status: 'failed',
  new_errors: [
    {
      description: "Parsing error: 'return' outside of function",
      severity: 'minor',
      file_path: 'index.js',
      line: 12,
    },
    {
      description: 'Avoid parameter lists longer than 5 parameters. [12/5]',
      check_name: 'Rubocop/Metrics/ParameterLists',
      severity: 'minor',
      file_path: 'main.rb',
      line: 3,
    },
  ],
  resolved_errors: [
    {
      description: "Parsing error: 'return' outside of function",
      severity: 'minor',
      file_path: 'index.js',
      line: 12,
    },
    {
      description: 'Avoid parameter lists longer than 5 parameters. [12/5]',
      check_name: 'Rubocop/Metrics/ParameterLists',
      severity: 'minor',
      file_path: 'main.rb',
      line: 3,
    },
  ],
  existing_errors: [],
  summary: {
    total: 12233,
    resolved: 1,
    errored: 12233,
  },
};

export const codeQualityResponseNoErrors = {
  status: 'failed',
  new_errors: [],
  resolved_errors: [],
  existing_errors: [],
  summary: {
    total: 12234,
    resolved: 0,
    errored: 12234,
  },
};
