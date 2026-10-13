import { s__, formatNumber } from '~/locale';

export const TIER_THRESHOLDS = [5, 25, 100];

// The API returns opaque `tier_0`, `tier_1`... values and leaves naming to the
// client. These names spell out TIER_THRESHOLDS, so the two change together.
export const TIER_NAMES = [
  s__('Glql|Light (1–4)'),
  s__('Glql|Regular (5–24)'),
  s__('Glql|Heavy (25–99)'),
  s__('Glql|Power (100+)'),
];

export const tierIndexOf = (value) => {
  const [, index] = /^tier_(\d+)$/.exec(value) ?? [];

  return index === undefined ? null : Number(index);
};

const NAMED_TIER_BANDS = { [TIER_THRESHOLDS.join()]: TIER_NAMES };

// The tiers bucket counts, so `tier_0`, which has no threshold below it,
// starts at 1.
export const tierBandFormatter = (thresholds) => {
  const bounds = thresholds.map(Number);
  const named = NAMED_TIER_BANDS[bounds.join()];

  return (value) => {
    const tier = tierIndexOf(value);
    if (tier === null || tier > bounds.length) return String(value);
    if (named?.[tier]) return named[tier];

    const from = tier === 0 ? 1 : bounds[tier - 1];
    const to = bounds[tier];

    return to === undefined
      ? `${formatNumber(from)}+`
      : `${formatNumber(from)}–${formatNumber(to - 1)}`;
  };
};
