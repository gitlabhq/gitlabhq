import { sprintf, n__, s__, __ } from '~/locale';
import {
  STATUS_FAILED,
  STATUS_SUCCESS,
  ICON_WARNING,
  ICON_SUCCESS,
  ICON_NOTFOUND,
} from '../constants';

const textBuilder = results => {
  const { failed, errored, resolved, total } = results;

  const failedOrErrored = (failed || 0) + (errored || 0);
  const failedString = failed ? n__('%d failed', '%d failed', failed) : null;
  const erroredString = errored ? n__('%d error', '%d errors', errored) : null;
  const combinedString =
    failed && errored ? `${failedString}, ${erroredString}` : failedString || erroredString;
  const resolvedString = resolved
    ? n__('%d fixed test result', '%d fixed test results', resolved)
    : null;
  const totalString = total ? n__('out of %d total test', 'out of %d total tests', total) : null;

  let resultsString = s__('Reports|no changed test results');

  if (failedOrErrored) {
    if (resolved) {
      resultsString = sprintf(s__('Reports|%{combinedString} and %{resolvedString}'), {
        combinedString,
        resolvedString,
      });
    } else {
      resultsString = combinedString;
    }
  } else if (resolved) {
    resultsString = resolvedString;
  }

  return `${resultsString} ${totalString}`;
};

export const summaryTextBuilder = (name = '', results = {}) => {
  const resultsString = textBuilder(results);
  return sprintf(__('%{name} contained %{resultsString}'), { name, resultsString });
};

export const reportTextBuilder = (name = '', results = {}) => {
  const resultsString = textBuilder(results);
  return sprintf(__('%{name} found %{resultsString}'), { name, resultsString });
};

export const statusIcon = status => {
  if (status === STATUS_FAILED) {
    return ICON_WARNING;
  }

  if (status === STATUS_SUCCESS) {
    return ICON_SUCCESS;
  }

  return ICON_NOTFOUND;
};
