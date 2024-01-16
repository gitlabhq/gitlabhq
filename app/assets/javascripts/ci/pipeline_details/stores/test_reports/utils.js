import { __, sprintf } from '~/locale';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { testStatus } from '../../constants';

/**
 * Removes `./` from the beginning of a file path so it can be appended onto a blob path
 * @param {String} file
 * @returns {String}  - formatted value
 */
export function formatFilePath(file) {
  return file.replace(/^\.?\/*/, '');
}

export function iconForTestStatus(status) {
  switch (status) {
    case testStatus.SUCCESS:
      return 'status_success';
    case testStatus.FAILED:
      return 'status_failed';
    case testStatus.ERROR:
      return 'status_warning';
    case testStatus.SKIPPED:
      return 'status_skipped';
    case testStatus.UNKNOWN:
    default:
      return 'status_notfound';
  }
}
export const formattedTime = (seconds = 0) => {
  if (seconds < 1) {
    return sprintf(__('%{milliseconds}ms'), {
      milliseconds: (seconds * 1000).toFixed(2),
    });
  }
  if (seconds < 60) {
    return sprintf(__('%{seconds}s'), {
      seconds: (seconds % 60).toFixed(2),
    });
  }

  const hoursAndMinutes = stringifyTime(parseSeconds(seconds));
  const remainingSeconds =
    seconds % 60 >= 1
      ? sprintf(__('%{seconds}s'), {
          seconds: Math.floor(seconds % 60),
        })
      : '';
  return `${hoursAndMinutes} ${remainingSeconds}`.trim();
};
export const addIconStatus = (testCase) => ({
  ...testCase,
  icon: iconForTestStatus(testCase.status),
  formattedTime: formattedTime(testCase.execution_time),
});
