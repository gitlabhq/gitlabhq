import { formatChange, trendChangeFor } from '~/glql/components/presenters/utils/trend';

describe('trendChangeFor', () => {
  it.each`
    value    | previousValue | expected
    ${120}   | ${100}        | ${0.2}
    ${80}    | ${100}        | ${-0.2}
    ${100}   | ${100}        | ${0}
    ${0}     | ${100}        | ${-1}
    ${0}     | ${0}          | ${0}
    ${1234}  | ${1000}       | ${0.234}
    ${10006} | ${10000}      | ${0.001}
  `('is $expected for $value against $previousValue', ({ value, previousValue, expected }) => {
    expect(trendChangeFor(value, previousValue)).toBe(expected);
  });

  it.each`
    value        | previousValue
    ${120}       | ${0}
    ${null}      | ${100}
    ${100}       | ${null}
    ${undefined} | ${100}
    ${100}       | ${undefined}
  `('has no change to show for $value against $previousValue', ({ value, previousValue }) => {
    expect(trendChangeFor(value, previousValue)).toBe(null);
  });

  // The badge renders one decimal place, so a change that rounds away has to be flat here
  // too, or the arrow and the ordering would disagree. Signed zero is what `Math.sign`
  // yields for a negative rounding to nothing; it compares equal to 0, so it sorts as flat.
  it.each`
    value    | previousValue | expected
    ${10004} | ${10000}      | ${0}
    ${9996}  | ${10000}      | ${-0}
  `(
    'rounds $value against $previousValue away to $expected',
    ({ value, previousValue, expected }) => {
      expect(trendChangeFor(value, previousValue)).toBe(expected);
    },
  );
});

describe('formatChange', () => {
  it.each`
    change   | expected
    ${0.2}   | ${'20%'}
    ${-0.2}  | ${'20%'}
    ${0}     | ${'0%'}
    ${0.234} | ${'23.4%'}
    ${0.001} | ${'0.1%'}
    ${-1}    | ${'100%'}
  `('formats $change as $expected', ({ change, expected }) => {
    expect(formatChange(change)).toBe(expected);
  });
});
