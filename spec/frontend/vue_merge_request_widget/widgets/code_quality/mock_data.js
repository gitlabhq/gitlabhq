export const newFindingWithoutEngineName = {
  description: 'Cyclomatic complexity is too high',
  severity: 'minor',
  file_path: 'app/services/foo.rb',
  line: 5,
  web_url: '/blob/app/services/foo.rb#L5',
};

export const newFinding = {
  ...newFindingWithoutEngineName,
  engine_name: 'rubocop',
};

export const resolvedFindingWithoutEngineName = {
  description: 'Unused variable',
  severity: 'minor',
  file_path: 'app/assets/javascripts/index.js',
  line: 10,
  web_url: '/blob/app/assets/javascripts/index.js#L10',
};

export const resolvedFinding = {
  ...resolvedFindingWithoutEngineName,
  engine_name: 'eslint',
};

export const responseNewFindings = {
  new_errors: [newFinding],
  resolved_errors: [],
};

export const responseResolvedFindings = {
  new_errors: [],
  resolved_errors: [resolvedFinding],
};

export const responseNewAndResolvedFindings = {
  new_errors: [newFinding],
  resolved_errors: [resolvedFinding],
};

export const responseNoFindings = {
  new_errors: [],
  resolved_errors: [],
};
