import { __, sprintf } from '../../../locale';
import { TestStatus } from '../../constants';

export function iconForTestStatus(status) {
  switch (status) {
    case TestStatus.SUCCESS:
      return 'status_success_borderless';
    case TestStatus.FAILED:
      return 'status_failed_borderless';
    case TestStatus.ERROR:
      return 'status_warning_borderless';
    case TestStatus.SKIPPED:
      return 'status_skipped_borderless';
    case TestStatus.UNKNOWN:
    default:
      return 'status_notfound_borderless';
  }
}

export const formattedTime = (seconds = 0) => {
  if (seconds < 1) {
    const milliseconds = seconds * 1000;
    return sprintf(__('%{milliseconds}ms'), { milliseconds: milliseconds.toFixed(2) });
  }
  return sprintf(__('%{seconds}s'), { seconds: seconds.toFixed(2) });
};

export const addIconStatus = testCase => ({
  ...testCase,
  icon: iconForTestStatus(testCase.status),
  formattedTime: formattedTime(testCase.execution_time),
});
