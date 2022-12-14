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
    total: 2,
    resolved: 0,
    errored: 2,
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
  ],
  resolved_errors: [
    {
      description: "Parsing error: 'return' outside of function",
      severity: 'minor',
      file_path: 'index.js',
      line: 12,
    },
  ],
  existing_errors: [],
  summary: {
    total: 2,
    resolved: 1,
    errored: 1,
  },
};

export const codeQualityResponseNoErrors = {
  status: 'failed',
  new_errors: [],
  resolved_errors: [],
  existing_errors: [],
  summary: {
    total: 0,
    resolved: 0,
    errored: 0,
  },
};
