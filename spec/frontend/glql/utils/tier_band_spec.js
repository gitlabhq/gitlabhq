import { tierBandFormatter, tierIndexOf } from '~/glql/utils/tier_band';

describe('tierIndexOf', () => {
  it.each`
    value        | expected
    ${'tier_0'}  | ${0}
    ${'tier_12'} | ${12}
    ${'tier'}    | ${null}
    ${'Unknown'} | ${null}
    ${undefined} | ${null}
  `('returns $expected for $value', ({ value, expected }) => {
    expect(tierIndexOf(value)).toBe(expected);
  });
});

describe('tierBandFormatter', () => {
  it.each`
    value           | expected
    ${'tier_0'}     | ${'Light (1–4)'}
    ${'tier_1'}     | ${'Regular (5–24)'}
    ${'tier_2'}     | ${'Heavy (25–99)'}
    ${'tier_3'}     | ${'Power (100+)'}
    ${'unexpected'} | ${'unexpected'}
  `('names the band $expected for $value', ({ value, expected }) => {
    expect(tierBandFormatter(['5', '25', '100'])(value)).toBe(expected);
  });

  it('derives the band from the thresholds when they name no tiers', () => {
    const format = tierBandFormatter(['10', '100']);

    expect(['tier_0', 'tier_1', 'tier_2'].map((value) => format(value))).toEqual([
      '1–9',
      '10–99',
      '100+',
    ]);
  });
});
