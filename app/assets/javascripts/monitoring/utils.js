import { timeWindows } from './constants';

export const getTimeDifferenceMinutes = timeWindow => {
  let timeDifferenceMinutes;
  switch (timeWindow) {
    case timeWindows.thirtyMinutes:
      timeDifferenceMinutes = 30;
      break;
    case timeWindows.threeHours:
      timeDifferenceMinutes = 60 * 3;
      break;
    case timeWindows.eightHours:
      timeDifferenceMinutes = 60 * 8;
      break;
    case timeWindows.oneDay:
      timeDifferenceMinutes = 60 * 24 * 1;
      break;
    case timeWindows.threeDays:
      timeDifferenceMinutes = 60 * 24 * 3;
      break;
    case timeWindows.oneWeek:
      timeDifferenceMinutes = 60 * 24 * 7 * 1;
      break;
    default:
      timeDifferenceMinutes = 60 * 8;
      break;
  }

  return timeDifferenceMinutes;
};

export default {};
