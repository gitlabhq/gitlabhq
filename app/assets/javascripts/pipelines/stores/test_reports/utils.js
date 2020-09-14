import { __, sprintf } from '../../../locale';

export function iconForTestStatus(status) {
  switch (status) {
    case 'success':
      return 'status_success_borderless';
    case 'failed':
      return 'status_failed_borderless';
    default:
      return 'status_skipped_borderless';
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
