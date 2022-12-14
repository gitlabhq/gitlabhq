import { n__, s__, sprintf } from '~/locale';

export const i18n = {
  label: s__('ciReport|Code Quality'),
  loading: s__('ciReport|Code Quality test metrics results are being parsed'),
  error: s__('ciReport|Code Quality failed loading results'),
  noChanges: s__(`ciReport|No changes to Code Quality.`),
  prependText: s__(`ciReport|in`),
  fixed: s__(`ciReport|Fixed`),
  pluralReport: (errors) =>
    sprintf(
      n__(
        '%{strong_start}%{errors}%{strong_end} point',
        '%{strong_start}%{errors}%{strong_end} points',
        errors.length,
      ),
      {
        errors: errors.length,
      },
      false,
    ),
  singularReport: (errors) => n__('%d point', '%d points', errors.length),
  improvementAndDegradationCopy: (improvement, degradation) =>
    sprintf(
      s__(`ciReport|Code Quality improved on ${improvement} and degraded on ${degradation}.`),
    ),
  improvedCopy: (improvements) =>
    sprintf(s__(`ciReport|Code Quality improved on ${improvements}.`)),
  degradedCopy: (degradations) =>
    sprintf(s__(`ciReport|Code Quality degraded on ${degradations}.`)),
};
