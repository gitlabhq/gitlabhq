import { __, sprintf } from '../../../locale';
import { TestStatus } from '../../constants';

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
    case TestStatus.SUCCESS:
      return 'status_success';
    case TestStatus.FAILED:
      return 'status_failed';
    case TestStatus.ERROR:
      return 'status_warning';
    case TestStatus.SKIPPED:
      return 'status_skipped';
    case TestStatus.UNKNOWN:
    default:
      return 'status_notfound';
  }
}

export const formattedTime = (seconds = 0) => {
  if (seconds < 1) {
    const milliseconds = seconds * 1000;
    return sprintf(__('%{milliseconds}ms'), { milliseconds: milliseconds.toFixed(2) });
  }
  return sprintf(__('%{seconds}s'), { seconds: seconds.toFixed(2) });
};

export const addIconStatus = (testCase) => ({
  ...testCase,
  icon: iconForTestStatus(testCase.status),
  formattedTime: formattedTime(testCase.execution_time),
});
