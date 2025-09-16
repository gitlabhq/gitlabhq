import { engineeringNotation } from '@gitlab/ui/src/utils/number_utils';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { stringifyTime, parseSeconds } from '~/lib/utils/datetime/date_format_utility';

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
  } catch {
    // return below
  }
  return undefined;
};

export const formatPipelineCountPercentage = (a, b) => {
  const percent = calculatePipelineCountPercentage(a, b);
  return percent !== undefined ? getFormatter(SUPPORTED_FORMATS.percentHundred)(percent, 0) : '-';
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
