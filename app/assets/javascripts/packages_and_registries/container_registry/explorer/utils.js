import { approximateDuration, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';

export const timeTilRun = (time) => {
  if (!time) return '';

  const difference = calculateRemainingMilliseconds(time);
  return approximateDuration(difference / 1000);
};
