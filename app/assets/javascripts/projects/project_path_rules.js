import { s__ } from '~/locale';

export const FORBIDDEN_SUFFIXES = ['.git', '.atom'];

export const START_RULE = {
  test: (value) => /^[a-zA-Z0-9]/.test(value),
  message: s__('ProjectsNew|Project slug must start with a letter or digit.'),
};

export const CONTAINS_RULE = {
  test: (value) => /^[a-zA-Z0-9_.-]+$/.test(value),
  message: s__(
    'ProjectsNew|Project slug can only contain letters, digits, underscores, periods, and dashes.',
  ),
};

export const END_RULE = {
  test: (value) => /[a-zA-Z0-9]$/.test(value),
  message: s__('ProjectsNew|Project slug must end with a letter or digit.'),
};

export const SEPARATOR_RULE = {
  test: (value) => !/[_.-]{2}/.test(value),
  message: s__(
    'ProjectsNew|Project slug must not contain consecutive underscores, periods, or dashes.',
  ),
};

export const SUFFIX_RULE = {
  test: (value) => !FORBIDDEN_SUFFIXES.some((suffix) => value.endsWith(suffix)),
  message: s__('ProjectsNew|Project slug must not end with `.git` or `.atom`.'),
};

// Mirrors the backend project path validations: `Gitlab::Regex.oci_repository_path_regex`
// (lib/gitlab/regex.rb) and `Gitlab::PathRegex.project_path_format_regex` (lib/gitlab/path_regex.rb).
// Keep these rules in sync with those regexes.
export const PATH_RULES = [START_RULE, CONTAINS_RULE, END_RULE, SEPARATOR_RULE, SUFFIX_RULE];

/**
 * Validate a project slug (path) against the format and length rules.
 *
 * The path is trimmed first, to match the trimming the form applies on submit.
 *
 * Returns the first matching error message, or an empty string if the path is
 * valid. Returns an empty string for an empty input so that the `required`
 * attribute can surface the empty-field error separately.
 *
 * @param {string} path
 * @returns {string}
 */
export const checkRules = (path) => {
  const slug = path.trim();

  if (!slug) return '';

  for (const rule of PATH_RULES) {
    if (!rule.test(slug)) return rule.message;
  }

  return '';
};
