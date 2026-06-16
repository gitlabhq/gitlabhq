import { engineeringNotation } from '@gitlab/ui/src/utils/number_utils';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { stringifyTime, parseSeconds } from '~/lib/utils/datetime/date_format_utility';
import { getDateInPast } from '~/lib/utils/datetime/date_calculation_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export const calculatePipelineCountPercentage = (a, b) => {
  try {
    // Dividing BigInt values loses the fractional part, multiply the numerator by a factor
    // and then divide the result to keep digits of precision.
    const factor = 1000; // 2 digits for percentage + 1 to round correctly
    const an = BigInt(a);
    const bn = BigInt(b);
    const ratio = Number((BigInt(factor) * an) / bn) / factor;
    if (Number.isFinite(ratio)) {
      return ratio * 100;
    }
  } catch (error) {
    Sentry.captureException(error);
    // return below
  }
  return undefined;
};

export const calculateDatesFromRelativeDays = (days) => {
  // Use UTC time and take beginning of day
  const today = new Date(new Date().setUTCHours(0, 0, 0, 0));

  return {
    fromTime: getDateInPast(today, days),
    toTime: today,
  };
};

export const formatPipelineCountPercentage = (a, b) => {
  const percent = calculatePipelineCountPercentage(a, b);
  return percent !== undefined ? getFormatter(SUPPORTED_FORMATS.percentHundred)(percent, 0) : '-';
};

// Returns BigInt(successCount) + BigInt(failedCount) as a string. Canceled/skipped
// are excluded so they don't dilute the rate. Falls back to `fallbackCount` on parse error.
export const calculateRateDenominator = (successCount, failedCount, fallbackCount = null) => {
  try {
    return (BigInt(successCount ?? 0) + BigInt(failedCount ?? 0)).toString();
  } catch (error) {
    Sentry.captureException(error);
    return fallbackCount;
  }
};

export const formatPipelineDuration = (seconds) => {
  if (Number.isFinite(seconds)) {
    return stringifyTime(parseSeconds(seconds, { daysPerWeek: 7, hoursPerDay: 24 }));
  }
  return '-';
};

export const formatPipelineDurationForAxis = (seconds) => {
  if (!Number.isFinite(seconds)) {
    return '-';
  }
  const minutes = seconds / 60;
  // using engineering notation for small amounts is strange, as we'd render "milliminutes"
  if (minutes < 1) {
    return minutes.toFixed(2).replace(/\.?0*$/, '');
  }
  return engineeringNotation(minutes, 2);
};
