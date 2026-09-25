import { __, n__, s__, sprintf } from '~/locale';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

const i18n = {
  reportGenerated: s__('Terraform|A Terraform report was generated in your pipelines.'),
  namedReportGenerated: s__(
    'Terraform|The job %{strong_start}%{name}%{strong_end} generated a report.',
  ),
  reportChanges: s__(
    'Terraform|Reported Resource Changes: %{addNum} to add, %{changeNum} to change, %{deleteNum} to delete',
  ),
  reportFailed: s__('Terraform|A Terraform report failed to generate.'),
  namedReportFailed: s__(
    'Terraform|The job %{strong_start}%{name}%{strong_end} failed to generate a report.',
  ),
  reportErrored: s__('Terraform|Generating the report caused an error.'),
  fullLog: __('Full log'),
};

const isValidReport = (report) =>
  report.create + report.update + report.delete >= 0 && !report.tf_report_error;

const isInvalidReport = (report) => !isValidReport(report);

const changeCount = (report) =>
  Number(report.create) + Number(report.update) + Number(report.delete);

const reportRow = (report, plainSupportingText) => {
  const { job_name: jobName, job_path: jobPath } = report;
  const isValid = isValidReport(report);
  let text;
  let supportingText;

  if (isValid) {
    text = jobName
      ? sprintf(i18n.namedReportGenerated, { name: jobName }, false)
      : i18n.reportGenerated;
    supportingText = sprintf(i18n.reportChanges, {
      addNum: report.create,
      changeNum: report.update,
      deleteNum: report.delete,
    });
  } else {
    text = jobName ? sprintf(i18n.namedReportFailed, { name: jobName }, false) : i18n.reportFailed;
    supportingText = i18n.reportErrored;
  }

  return {
    text,
    supportingText: plainSupportingText
      ? supportingText
      : `%{small_start}${supportingText}%{small_end}`,
    icon: { name: isValid ? EXTENSION_ICONS.success : EXTENSION_ICONS.error },
    actions: jobPath
      ? [{ href: jobPath, text: i18n.fullLog, target: '_blank', trackFullReportClicked: true }]
      : [],
  };
};

export const terraformInvalidCount = (data) =>
  Object.values(data || {}).filter(isInvalidReport).length;

export const terraformSummary = (data) => {
  const reports = Object.values(data || {});
  const validCount = reports.filter(isValidReport).length;
  const invalidCount = reports.length - validCount;

  const validText = sprintf(
    n__(
      'Terraform|%{strong_start}%{number}%{strong_end} Terraform report was generated in your pipelines',
      'Terraform|%{strong_start}%{number}%{strong_end} Terraform reports were generated in your pipelines',
      validCount,
    ),
    { number: validCount },
    false,
  );

  const invalidText = sprintf(
    n__(
      'Terraform|%{strong_start}%{number}%{strong_end} Terraform report failed to generate',
      'Terraform|%{strong_start}%{number}%{strong_end} Terraform reports failed to generate',
      invalidCount,
    ),
    { number: invalidCount },
    false,
  );

  return {
    title: validCount ? validText : invalidText,
    subtitle: validCount && invalidCount ? invalidText : undefined,
  };
};

export const terraformRows = (data, { plainSupportingText = false } = {}) => {
  const reports = Object.values(data || {}).sort((a, b) => changeCount(b) - changeCount(a));

  return [...reports.filter(isValidReport), ...reports.filter(isInvalidReport)].map((report) =>
    reportRow(report, plainSupportingText),
  );
};
