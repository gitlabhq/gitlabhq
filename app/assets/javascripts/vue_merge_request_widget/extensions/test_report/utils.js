import { i18n } from './constants';

const textBuilder = (results, boldNumbers = false) => {
  const { failed, errored, resolved, total } = results;

  const failedOrErrored = (failed || 0) + (errored || 0);
  const failedString = failed ? i18n.failedClause(failed, boldNumbers) : null;
  const erroredString = errored ? i18n.erroredClause(errored, boldNumbers) : null;
  const combinedString =
    failed && errored ? `${failedString}, ${erroredString}` : failedString || erroredString;
  const resolvedString = resolved ? i18n.resolvedClause(resolved, boldNumbers) : null;
  const totalString = total ? i18n.totalClause(total, boldNumbers) : null;

  let resultsString = i18n.noChanges(boldNumbers);

  if (failedOrErrored) {
    if (resolved) {
      resultsString = i18n.resultsString(combinedString, resolvedString);
    } else {
      resultsString = combinedString;
    }
  } else if (resolved) {
    resultsString = resolvedString;
  }

  return `${resultsString}, ${totalString}`;
};

export const summaryTextBuilder = (name = '', results = {}) => {
  const resultsString = textBuilder(results, true);
  return i18n.summaryText(name, resultsString);
};

export const reportTextBuilder = ({ name = '', summary = {}, status }) => {
  if (!name) {
    return i18n.reportError;
  }
  if (status === 'error') {
    return i18n.reportErrorWithName(name);
  }

  const resultsString = textBuilder(summary);
  return i18n.summaryText(name, resultsString);
};

export const reportSubTextBuilder = ({ suite_errors }) => {
  const errors = [];
  if (suite_errors?.head) {
    errors.push(`${i18n.headReportParsingError} ${suite_errors.head}`);
  }
  if (suite_errors?.base) {
    errors.push(`${i18n.baseReportParsingError} ${suite_errors.base}`);
  }
  return errors.join('<br />');
};
