import { n__, s__, __, sprintf } from '~/locale';

export const codeQualityPrefixes = {
  fixed: 'fixed',
  new: 'new',
};

export const i18n = {
  label: s__('ciReport|Code Quality'),
  loading: s__('ciReport|Code Quality is loading'),
  error: s__('ciReport|Code Quality failed to load results'),
  noChanges: s__(`ciReport|Code Quality hasn't changed.`),
  prependText: s__(`ciReport|in`),
  fixed: s__(`ciReport|Fixed`),
  findings: (errors, prefix) =>
    sprintf(
      n__(
        '%{strong_start}%{errors}%{strong_end} %{prefix} finding',
        '%{strong_start}%{errors}%{strong_end} %{prefix} findings',
        errors.length,
      ),
      {
        errors: errors.length,
        prefix,
      },
      false,
    ),
  improvementAndDegradationCopy: (improvement, degradation) =>
    sprintf(__('Code Quality scans found %{degradation} and %{improvement}.'), {
      improvement,
      degradation,
    }),
  singularCopy: (findings) =>
    sprintf(__('Code Quality scans found %{findings}.'), { findings }, false),
};
