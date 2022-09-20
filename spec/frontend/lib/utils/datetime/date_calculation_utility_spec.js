import {
  getDateWithUTC,
  newDateAsLocaleTime,
  formatUtcOffset,
} from '~/lib/utils/datetime/date_calculation_utility';

describe('newDateAsLocaleTime', () => {
  it.each`
    string                        | expected
    ${'2022-03-22'}               | ${new Date('2022-03-22T00:00:00.000Z')}
    ${'2022-03-22T00:00:00.000Z'} | ${new Date('2022-03-22T00:00:00.000Z')}
    ${2022}                       | ${null}
    ${[]}                         | ${null}
    ${{}}                         | ${null}
    ${true}                       | ${null}
    ${null}                       | ${null}
    ${undefined}                  | ${null}
  `('returns $expected given $string', ({ string, expected }) => {
    expect(newDateAsLocaleTime(string)).toEqual(expected);
  });
});

describe('getDateWithUTC', () => {
  it.each`
    date                                    | expected
    ${new Date('2022-03-22T01:23:45.678Z')} | ${new Date('2022-03-22T00:00:00.000Z')}
    ${new Date('1999-12-31T23:59:59.999Z')} | ${new Date('1999-12-31T00:00:00.000Z')}
    ${2022}                                 | ${null}
    ${[]}                                   | ${null}
    ${{}}                                   | ${null}
    ${true}                                 | ${null}
    ${null}                                 | ${null}
    ${undefined}                            | ${null}
  `('returns $expected given $string', ({ date, expected }) => {
    expect(getDateWithUTC(date)).toEqual(expected);
  });
});

describe('formatUtcOffset', () => {
  it.each`
    offset       | expected
    ${-32400}    | ${'- 9'}
    ${'-12600'}  | ${'- 3.5'}
    ${0}         | ${'0'}
    ${'10800'}   | ${'+ 3'}
    ${19800}     | ${'+ 5.5'}
    ${0}         | ${'0'}
    ${[]}        | ${'0'}
    ${{}}        | ${'0'}
    ${true}      | ${'0'}
    ${null}      | ${'0'}
    ${undefined} | ${'0'}
  `('returns $expected given $offset', ({ offset, expected }) => {
    expect(formatUtcOffset(offset)).toEqual(expected);
  });
});
