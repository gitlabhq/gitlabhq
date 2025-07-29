import { engineeringNotation } from '@gitlab/ui/dist/utils/number_utils';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { stringifyTime, parseSeconds } from '~/lib/utils/datetime/date_format_utility';
import { formatNumber } from '~/locale';

export const formatPipelineCount = (count) => {
  try {
    const n = BigInt(count);
    return formatNumber(n);
  } catch {
    return '-';
  }
};

export const formatPipelineCountPercentage = (a, b) => {
  try {
    // Dividing BigInt values loses the fractional part, multiply the numerator by a factor
    // and then divide the result to keep digits of precision.
    const factor = 1000; // 2 digits for percentage + 1 to round correctly
    const an = BigInt(a);
    const bn = BigInt(b);
    const ratio = Number((BigInt(factor) * an) / bn) / factor;
    if (Number.isFinite(ratio)) {
      return getFormatter(SUPPORTED_FORMATS.percentHundred)(ratio * 100, 0);
    }
  } catch {
    // return below
  }
  return '-';
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
