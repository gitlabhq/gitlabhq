import { formatTime } from '~/lib/utils/datetime_utility';

// eslint-disable-next-line import/prefer-default-export
export const addRemainingTime = delayedAction => {
  if (!delayedAction.scheduled_at) {
    return delayedAction;
  }

  const remainingMilliseconds = new Date(delayedAction.scheduled_at).getTime() - Date.now();
  return {
    ...delayedAction,
    remainingTime: formatTime(Math.max(0, remainingMilliseconds)),
  };
};
