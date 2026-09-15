import { formatNumber } from '~/locale';

// Rounded half away from zero to the one decimal a trend renders, so the arrow and colour
// agree with the text: 10,004 against 10,000 reads `0%` with no arrow rather than an up arrow.
const roundChange = (change) => (Math.sign(change) * Math.round(Math.abs(change) * 1000)) / 1000;

/**
 * Resolves the signed fractional change from `previousValue` to `value`, rounded to the
 * precision a trend renders, or null when there is no number to show. Shared with callers
 * that sort by the change, so the ordering can never disagree with the rendered value.
 */
export const trendChangeFor = (value, previousValue) => {
  if (value == null || previousValue == null) return null;
  if (value === previousValue) return 0;
  // A move away from 0 has no percentage; callers label it as new instead.
  if (previousValue === 0) return null;

  return roundChange((value - previousValue) / previousValue);
};

/**
 * Formats a change as an unsigned percentage. The sign is carried by the arrow, the colour
 * and the tooltip, so a caller that renders the number alone must supply its own direction.
 */
export const formatChange = (change) =>
  formatNumber(Math.abs(change), { style: 'percent', maximumFractionDigits: 1 });
