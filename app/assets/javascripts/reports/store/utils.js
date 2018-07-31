import { sprintf, n__, s__ } from '~/locale';
import {
  STATUS_FAILED,
  STATUS_SUCCESS,
  ICON_WARNING,
  ICON_SUCCESS,
  ICON_NOTFOUND,
} from '../constants';

const textBuilder = results => {
  const { failed, resolved, total } = results;

  const failedString = failed
    ? n__('%d failed test result', '%d failed test results', failed)
    : null;
  const resolvedString = resolved
    ? n__('%d fixed test result', '%d fixed test results', resolved)
    : null;
  const totalString = total ? n__('out of %d total test', 'out of %d total tests', total) : null;
  let resultsString;

  if (failed) {
    if (resolved) {
      resultsString = sprintf(s__('Reports|%{failedString} and %{resolvedString}'), {
        failedString,
        resolvedString,
      });
    } else {
      resultsString = failedString;
    }
  } else if (resolved) {
    resultsString = resolvedString;
  } else {
    resultsString = s__('Reports|no changed test results');
  }

  return `${resultsString} ${totalString}`;
};

export const summaryTextBuilder = (name = '', results) => {
  const resultsString = textBuilder(results);
  return `${name} contained ${resultsString}`;
};

export const reportTextBuilder = (name = '', results) => {
  const resultsString = textBuilder(results);
  return `${name} found ${resultsString}`;
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
