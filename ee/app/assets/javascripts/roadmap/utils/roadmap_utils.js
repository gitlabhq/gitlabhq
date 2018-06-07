import { getTimeframeWindowFrom, totalDaysInMonth } from '~/lib/utils/datetime_utility';

import { PRESET_TYPES, PRESET_DEFAULTS } from '../constants';

/**
 * This method returns array of Objects representing Quarters based on provided initialDate
 *
 * For eg; If initialDate is 15th Jan 2018
 *         Then as per Roadmap specs, we need to show
 *         1 quarter before current quarter AND
 *         4 quarters after current quarter
 *         thus, total of 6 quarters.
 *
 * So returned array from this method will be;
 *        [
 *          {
 *            quarterSequence: 4,
 *            year: 2017,
 *            range: [
 *              1 Oct 2017,
 *              1 Nov 2017,
 *              31 Dec 2017,
 *            ],
 *          },
 *          {
 *            quarterSequence: 1,
 *            year: 2018,
 *            range: [
 *              1 Jan 2018,
 *              1 Feb 2018,
 *              31 Mar 2018,
 *            ],
 *          },
 *          ....
 *          ....
 *          ....
 *          {
 *            quarterSequence: 1,
 *            year: 2019,
 *            range: [
 *              1 Jan 2019,
 *              1 Feb 2019,
 *              31 Mar 2019,
 *            ],
 *          },
 *        ]
 *
 * @param {Date} initialDate
 */
export const getTimeframeForQuartersView = (initialDate = new Date()) => {
  const startDate = initialDate;
  startDate.setHours(0, 0, 0, 0);

  const monthsForQuarters = {
    1: [0, 1, 2],
    2: [3, 4, 5],
    3: [6, 7, 8],
    4: [9, 10, 11],
  };

  // Get current quarter for current month
  const currentQuarter = Math.floor((startDate.getMonth() + 3) / 3);
  // Get index of current month in current quarter
  // It could be 0, 1, 2 (i.e. first, second or third)
  const currentMonthInCurrentQuarter = monthsForQuarters[currentQuarter].indexOf(
    startDate.getMonth(),
  );

  // To move start back to first month of previous quarter
  // Adding quarter size (3) to month order will give us
  // exact number of months we need to go back in time
  const startMonth = currentMonthInCurrentQuarter + 3;
  const quartersTimeframe = [];
  // Move startDate to first month of previous quarter
  startDate.setMonth(startDate.getMonth() - startMonth);

  // Get timeframe for the length we determined for this preset
  // start from the startDate
  const timeframe = getTimeframeWindowFrom(startDate, PRESET_DEFAULTS.QUARTERS.TIMEFRAME_LENGTH);

  // Iterate over the timeframe and break it down
  // in chunks of quarters
  for (let i = 0; i < timeframe.length; i += 3) {
    const range = timeframe.slice(i, i + 3);
    const lastMonthOfQuarter = range[range.length - 1];
    const quarterSequence = Math.floor((range[0].getMonth() + 3) / 3);
    const year = range[0].getFullYear();

    // Ensure that `range` spans across duration of
    // entire quarter
    lastMonthOfQuarter.setDate(totalDaysInMonth(lastMonthOfQuarter));

    quartersTimeframe.push({
      quarterSequence,
      range,
      year,
    });
  }

  return quartersTimeframe;
};

/**
 * This method returns array of Dates respresenting Months based on provided initialDate
 *
 * For eg; If initialDate is 15th Jan 2018
 *         Then as per Roadmap specs, we need to show
 *         1 month before current month AND
 *         5 months after current month
 *         thus, total of 7 months.
 *
 * So returned array from this method will be;
 *        [
 *          1 Dec 2017, 1 Jan 2018, 1 Feb 2018, 1 Mar 2018,
 *          1 Apr 2018, 1 May 2018, 30 Jun 2018
 *        ]
 *
 * @param {Date} initialDate
 */
export const getTimeframeForMonthsView = (initialDate = new Date()) => {
  const startDate = initialDate;
  startDate.setHours(0, 0, 0, 0);

  // Move startDate to a month prior to current month
  startDate.setMonth(startDate.getMonth() - 1);

  return getTimeframeWindowFrom(startDate, PRESET_DEFAULTS.MONTHS.TIMEFRAME_LENGTH);
};

/**
 * This method returns array of Dates respresenting Months based on provided initialDate
 *
 * For eg; If initialDate is 15th Jan 2018
 *         Then as per Roadmap specs, we need to show
 *         1 week before current week AND
 *         4 weeks after current week
 *         thus, total of 6 weeks.
 *         Note that week starts on Sunday
 *
 * So returned array from this method will be;
 *        [
 *          7 Jan 2018, 14 Jan 2018, 21 Jan 2018,
 *          28 Jan 2018, 4 Mar 2018, 11 Mar 2018
 *        ]
 *
 * @param {Date} initialDate
 */
export const getTimeframeForWeeksView = (initialDate = new Date()) => {
  const startDate = initialDate;
  startDate.setHours(0, 0, 0, 0);

  const dayOfWeek = startDate.getDay();
  const daysToFirstDayOfPrevWeek = dayOfWeek + 7;
  const timeframe = [];

  // Move startDate to first day (Sunday) of previous week
  startDate.setDate(startDate.getDate() - daysToFirstDayOfPrevWeek);

  // Iterate for the length of this preset
  for (let i = 0; i < PRESET_DEFAULTS.WEEKS.TIMEFRAME_LENGTH; i += 1) {
    // Push date to timeframe only when day is
    // first day (Sunday) of the week1
    if (startDate.getDay() === 0) {
      timeframe.push(new Date(startDate.getTime()));
    }
    // Move date one day further
    startDate.setDate(startDate.getDate() + 1);
  }

  return timeframe;
};

export const getTimeframeForPreset = (presetType = PRESET_TYPES.MONTHS) => {
  if (presetType === PRESET_TYPES.QUARTERS) {
    return getTimeframeForQuartersView();
  } else if (presetType === PRESET_TYPES.MONTHS) {
    return getTimeframeForMonthsView();
  }
  return getTimeframeForWeeksView();
};

export const getEpicsPathForPreset = ({
  basePath = '',
  filterQueryString = '',
  presetType = '',
  timeframe = [],
}) => {
  let start;
  let end;
  let epicsPath = basePath;

  if (!basePath || !timeframe.length) {
    return null;
  }

  // Construct Epic API path to include
  // `start_date` & `end_date` query params to get list of
  // epics only for timeframe.
  if (presetType === PRESET_TYPES.QUARTERS) {
    const firstTimeframe = timeframe[0];
    const lastTimeframe = timeframe[timeframe.length - 1];

    start = firstTimeframe.range[0];
    end = lastTimeframe.range[lastTimeframe.range.length - 1];
  } else if (presetType === PRESET_TYPES.MONTHS) {
    start = timeframe[0];
    end = timeframe[timeframe.length - 1];
  } else if (presetType === PRESET_TYPES.WEEKS) {
    start = timeframe[0];
    end = new Date(timeframe[timeframe.length - 1].getTime());
    end.setDate(end.getDate() + 6);
  }

  const startDate = `${start.getFullYear()}-${start.getMonth() + 1}-${start.getDate()}`;
  const endDate = `${end.getFullYear()}-${end.getMonth() + 1}-${end.getDate()}`;
  epicsPath += `?start_date=${startDate}&end_date=${endDate}`;

  if (filterQueryString) {
    epicsPath += `&${filterQueryString}`;
  }

  return epicsPath;
};
