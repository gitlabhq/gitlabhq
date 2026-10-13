import { __, n__, s__, sprintf } from '~/locale';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

const TECHS_CODE_INDEX = 4;

const learnMoreUrl = (code) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `https://www.w3.org/TR/WCAG20-TECHS/${code?.split('.')[TECHS_CODE_INDEX] || 'Overview'}.html`;

const transformError = (error, iconName) => ({
  text: sprintf(
    s__(
      'AccessibilityReport|The accessibility scanning found an error of the following type: %{code}',
    ),
    { code: error.code },
  ),
  icon: { name: iconName },
  supportingText: sprintf(s__('AccessibilityReport|Message: %{message}'), {
    message: error.message,
  }),
  actions: [
    {
      text: __('Details'),
      icon: 'external-link',
      href: learnMoreUrl(error.code),
      target: '_blank',
      rel: 'noopener noreferrer', // eslint-disable-line @gitlab/require-i18n-strings
      variant: 'link',
    },
  ],
});

export const accessibilityErrorCount = (data) => data?.summary?.errored || 0;

export const accessibilitySummaryText = (errorCount) =>
  errorCount === 0
    ? s__('Reports|Accessibility scanning detected no issues for the source branch only')
    : sprintf(
        n__(
          'Reports|Accessibility scanning detected %{strong_start}%{number}%{strong_end} issue for the source branch only',
          'Reports|Accessibility scanning detected %{strong_start}%{number}%{strong_end} issues for the source branch only',
          errorCount,
        ),
        { number: errorCount },
        false,
      );

export const accessibilitySections = (data) =>
  [
    { header: __('New'), errors: data?.new_errors, icon: EXTENSION_ICONS.failed },
    { header: __('Not fixed'), errors: data?.existing_errors, icon: EXTENSION_ICONS.failed },
    { header: __('Fixed'), errors: data?.resolved_errors, icon: EXTENSION_ICONS.success },
  ]
    .filter(({ errors }) => errors?.length)
    .map(({ header, errors, icon }) => ({
      header,
      children: errors.map((error) => transformError(error, icon)),
    }));

export const accessibilityWidgetItems = (data) =>
  accessibilitySections(data).flatMap(({ header, children }) =>
    children.map((child, index) => ({ ...child, header: index === 0 ? header : '' })),
  );
