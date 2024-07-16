import {
  getDateWithUTC,
  getCurrentUtcDate,
  newDateAsLocaleTime,
  nSecondsAfter,
  nSecondsBefore,
  isToday,
  isInTimePeriod,
  differenceInMinutes,
  getMonthsBetweenDates,
} from '~/lib/utils/datetime/date_calculation_utility';
import { useFakeDate } from 'helpers/fake_date';

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

describe('nSecondsAfter', () => {
  const start = new Date('2022-03-22T01:23:45.678Z');
  it.each`
    date     | seconds  | expected
    ${start} | ${0}     | ${start}
    ${start} | ${1}     | ${new Date('2022-03-22T01:23:46.678Z')}
    ${start} | ${5}     | ${new Date('2022-03-22T01:23:50.678Z')}
    ${start} | ${60}    | ${new Date('2022-03-22T01:24:45.678Z')}
    ${start} | ${3600}  | ${new Date('2022-03-22T02:23:45.678Z')}
    ${start} | ${86400} | ${new Date('2022-03-23T01:23:45.678Z')}
  `('returns $expected given $string', ({ date, seconds, expected }) => {
    expect(nSecondsAfter(date, seconds)).toEqual(expected);
  });
});

describe('nSecondsBefore', () => {
  const start = new Date('2022-03-22T01:23:45.678Z');
  it.each`
    date     | seconds  | expected
    ${start} | ${0}     | ${start}
    ${start} | ${1}     | ${new Date('2022-03-22T01:23:44.678Z')}
    ${start} | ${5}     | ${new Date('2022-03-22T01:23:40.678Z')}
    ${start} | ${60}    | ${new Date('2022-03-22T01:22:45.678Z')}
    ${start} | ${3600}  | ${new Date('2022-03-22T00:23:45.678Z')}
    ${start} | ${86400} | ${new Date('2022-03-21T01:23:45.678Z')}
  `('returns $expected given $string', ({ date, seconds, expected }) => {
    expect(nSecondsBefore(date, seconds)).toEqual(expected);
  });
});

describe('isToday', () => {
  useFakeDate(2022, 11, 5);

  describe('when date is today', () => {
    it('returns `true`', () => {
      expect(isToday(new Date(2022, 11, 5))).toBe(true);
    });
  });

  describe('when date is not today', () => {
    it('returns `false`', () => {
      expect(isToday(new Date(2022, 11, 6))).toBe(false);
    });
  });
});

describe('getCurrentUtcDate', () => {
  useFakeDate(2022, 11, 5, 10, 10);

  it('returns the date at midnight', () => {
    expect(getCurrentUtcDate()).toEqual(new Date('2022-12-05T00:00:00.000Z'));
  });
});

describe('isInTimePeriod', () => {
  const date = '2022-03-22T01:23:45.000Z';

  it.each`
    start                         | end                           | expected
    ${'2022-03-21'}               | ${'2022-03-23'}               | ${true}
    ${'2022-03-20'}               | ${'2022-03-21'}               | ${false}
    ${'2022-03-23'}               | ${'2022-03-24'}               | ${false}
    ${date}                       | ${'2022-03-24'}               | ${true}
    ${'2022-03-21'}               | ${date}                       | ${true}
    ${'2022-03-22T00:23:45.000Z'} | ${'2022-03-22T02:23:45.000Z'} | ${true}
    ${'2022-03-22T00:23:45.000Z'} | ${'2022-03-22T00:25:45.000Z'} | ${false}
    ${'2022-03-22T02:23:45.000Z'} | ${'2022-03-22T03:25:45.000Z'} | ${false}
  `('returns $expected for range: $start -> $end', ({ start, end, expected }) => {
    expect(isInTimePeriod(new Date(date), new Date(start), new Date(end))).toBe(expected);
  });
});

describe('differenceInMinutes', () => {
  it.each`
    start           | end                           | expected
    ${'2024-06-07'} | ${'2024-06-07'}               | ${0}
    ${'2024-06-07'} | ${'2024-06-07T01:00:00.000Z'} | ${60}
    ${'2024-06-07'} | ${'2024-06-07T00:10:00.000Z'} | ${10}
    ${'2024-06-07'} | ${'2024-06-07T00:00:10.000Z'} | ${1}
  `('returns difference in minuts for range: $start -> $end', ({ start, end, expected }) => {
    expect(differenceInMinutes(new Date(start), new Date(end))).toBe(expected);
  });
});

describe('getMonthsBetweenDates', () => {
  it.each`
    startDate       | endDate         | expected
    ${'2024-03-01'} | ${'2024-01-01'} | ${[]}
    ${'2024-03-01'} | ${'2024-03-15'} | ${[{ month: 2, year: 2024 }]}
    ${'2024-01-01'} | ${'2024-03-31'} | ${[{ month: 0, year: 2024 }, { month: 1, year: 2024 }, { month: 2, year: 2024 }]}
    ${'2023-12-01'} | ${'2024-02-28'} | ${[{ month: 11, year: 2023 }, { month: 0, year: 2024 }, { month: 1, year: 2024 }]}
  `('with $startDate and $endDate, returns $expected', ({ startDate, endDate, expected }) => {
    const actual = getMonthsBetweenDates(new Date(startDate), new Date(endDate));

    expect(actual).toEqual(expected);
  });

  it('with large date range starting in middle of year, works as expected', () => {
    const actual = getMonthsBetweenDates(new Date('2024-05-01'), new Date('2026-03-01'));

    expect(actual).toEqual([
      { month: 4, year: 2024 },
      { month: 5, year: 2024 },
      { month: 6, year: 2024 },
      { month: 7, year: 2024 },
      { month: 8, year: 2024 },
      { month: 9, year: 2024 },
      { month: 10, year: 2024 },
      { month: 11, year: 2024 },
      { month: 0, year: 2025 },
      { month: 1, year: 2025 },
      { month: 2, year: 2025 },
      { month: 3, year: 2025 },
      { month: 4, year: 2025 },
      { month: 5, year: 2025 },
      { month: 6, year: 2025 },
      { month: 7, year: 2025 },
      { month: 8, year: 2025 },
      { month: 9, year: 2025 },
      { month: 10, year: 2025 },
      { month: 11, year: 2025 },
      { month: 0, year: 2026 },
      { month: 1, year: 2026 },
      { month: 2, year: 2026 },
    ]);
  });
});
