/**
 * Return the data range for the given time period
 * Accepted values are numbers followed by the unit 'm', 'h', 'd', e.g. '5m', '3h', '7d'
 *
 *  e.g. timePerdio: '5m'
 *      returns: { min: Date(_now - 5min_), max: Date(_now_) }
 *
 * @param {String} timePeriod The 'period' string
 * @returns {{max: Date, min: Date}|{}} where max, min are Date objects representing the period range
 *  It returns {} if the period filter does not represent any range (invalid range, etc)
 */
export const periodToDate = (timePeriod) => {
  const maxMs = Date.now();
  let minMs;
  const periodValue = parseInt(timePeriod.slice(0, -1), 10);
  if (Number.isNaN(periodValue) || periodValue <= 0) return {};

  const unit = timePeriod[timePeriod.length - 1];
  switch (unit) {
    case 'm':
      minMs = periodValue * 60 * 1000;
      break;
    case 'h':
      minMs = periodValue * 60 * 1000 * 60;
      break;
    case 'd':
      minMs = periodValue * 60 * 1000 * 60 * 24;
      break;
    default:
      return {};
  }
  return { min: new Date(maxMs - minMs), max: new Date(maxMs) };
};
