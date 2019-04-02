import { timeWindows, msPerMinute } from './constants';

const getTimeDifferenceMinutes = timeWindow => {
  switch (timeWindow) {
    case timeWindows.thirtyMinutes:
      return 30;
    case timeWindows.threeHours:
      return 60 * 3;
    case timeWindows.oneDay:
      return 60 * 24 * 1;
    case timeWindows.threeDays:
      return 60 * 24 * 3;
    case timeWindows.oneWeek:
      return 60 * 24 * 7 * 1;
    default:
      return 60 * 8;
  }
};

export const getTimeDiff = selectedTimeWindow => {
  const end = Date.now();
  const timeDifferenceMinutes = getTimeDifferenceMinutes(selectedTimeWindow);
  const start = new Date(end - timeDifferenceMinutes * msPerMinute).getTime();

  return { start, end };
};

export default {};
