import timezoneMock from 'timezone-mock';
import {
  approximateDuration,
  calculateRemainingMilliseconds,
  cloneDate,
  convertMsToNano,
  convertNanoToMs,
  dateAtFirstDayOfMonth,
  datesMatch,
  dayAfter,
  differenceInMilliseconds,
  differenceInMinutes,
  differenceInMonths,
  differenceInSeconds,
  fallsBefore,
  format24HourTimeStringFromInt,
  getCurrentUtcDate,
  getDateInFuture,
  getDateInPast,
  getDatesInRange,
  getDayDifference,
  getMonthsBetweenDates,
  getStartOfDay,
  getStartOfWeek,
  getSundays,
  getTimeframeWindowFrom,
  getTimeRemainingInWords,
  isInFuture,
  isInPast,
  isInTimePeriod,
  isToday,
  isValidDate,
  nDaysAfter,
  nDaysBefore,
  newDate,
  nMonthsAfter,
  nMonthsBefore,
  nSecondsAfter,
  nSecondsBefore,
  nHoursAfter,
  nWeeksAfter,
  nWeeksBefore,
  nYearsAfter,
  nYearsBefore,
  removeTime,
  secondsToDays,
  secondsToMilliseconds,
  totalDaysInMonth,
  daysToSeconds,
} from '~/lib/utils/datetime/date_calculation_utility';
import { useFakeDate } from 'helpers/fake_date';

describe('newDate', () => {
  it.each`
    string                             | expected
    ${'2022-03-22'}                    | ${new Date('2022-03-22T00:00:00.000Z')}
    ${'2022-03-22T00:00'}              | ${new Date('2022-03-22T00:00:00.000Z')}
    ${'2022-03-22T00:00:00'}           | ${new Date('2022-03-22T00:00:00.000Z')}
    ${'2022-03-22T00:00:00.000'}       | ${new Date('2022-03-22T00:00:00.000Z')}
    ${'2022-03-22T00:00:00.000Z'}      | ${new Date('2022-03-22T00:00:00.000Z')}
    ${'2022-03-22T01:00:00.000+01:00'} | ${new Date('2022-03-22T00:00:00.000Z')}
    ${1647907200000}                   | ${new Date('2022-03-22T00:00:00.000Z')}
    ${new Date('2022-03-22T00:00')}    | ${new Date('2022-03-22T00:00:00.000Z')}
    ${null}                            | ${null}
    ${undefined}                       | ${undefined}
  `('returns $expected given $string when timezone=GMT', ({ string, expected }) => {
    expect(newDate(string)).toEqual(expected);
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

describe('convertNanoToMs', () => {
  it('converts nanoseconds to milliseconds correctly', () => {
    expect(convertNanoToMs(1e6)).toBe(1);
    expect(convertNanoToMs(5e6)).toBe(5);
    expect(convertNanoToMs(1e9)).toBe(1000);
  });

  it('handles zero', () => {
    expect(convertNanoToMs(0)).toBe(0);
  });

  it('handles fractional nanoseconds', () => {
    expect(convertNanoToMs(1567000)).toBe(1.567);
  });
});

describe('convertMsToNano', () => {
  it('converts milliseconds to nanoseconds correctly', () => {
    expect(convertMsToNano(5)).toBe(5e6);
    expect(convertMsToNano(1234)).toBe(1234000000);
  });

  it('handles zero', () => {
    expect(convertMsToNano(0)).toBe(0);
  });

  it('handles fractional milliseconds', () => {
    expect(convertMsToNano(1.5)).toBe(1500000);
  });
});

describe('get day difference', () => {
  it('should return 7', () => {
    const firstDay = new Date('07/01/2016');
    const secondDay = new Date('07/08/2016');
    const difference = getDayDifference(firstDay, secondDay);

    expect(difference).toBe(7);
  });

  it('should return 31', () => {
    const firstDay = new Date('07/01/2016');
    const secondDay = new Date('08/01/2016');
    const difference = getDayDifference(firstDay, secondDay);

    expect(difference).toBe(31);
  });

  it('should return 365', () => {
    const firstDay = new Date('07/02/2015');
    const secondDay = new Date('07/01/2016');
    const difference = getDayDifference(firstDay, secondDay);

    expect(difference).toBe(365);
  });
});

describe('totalDaysInMonth', () => {
  it('returns number of days in a month for given date', () => {
    // 1st Feb, 2016 (leap year)
    expect(totalDaysInMonth(new Date(2016, 1, 1))).toBe(29);

    // 1st Feb, 2017
    expect(totalDaysInMonth(new Date(2017, 1, 1))).toBe(28);

    // 1st Jan, 2017
    expect(totalDaysInMonth(new Date(2017, 0, 1))).toBe(31);
  });
});

describe('getSundays', () => {
  it('returns array of dates representing all Sundays of the month', () => {
    // December, 2017 (it has 5 Sundays)
    const dateOfSundays = [3, 10, 17, 24, 31];
    const sundays = getSundays(new Date(2017, 11, 1));

    expect(sundays.length).toBe(5);
    sundays.forEach((sunday, index) => {
      expect(sunday.getDate()).toBe(dateOfSundays[index]);
    });
  });
});

describe('getTimeframeWindowFrom', () => {
  it('returns array of date objects upto provided length (positive number) into the future starting from provided startDate', () => {
    const startDate = new Date(2018, 0, 1);
    const mockTimeframe = [
      new Date(2018, 0, 1),
      new Date(2018, 1, 1),
      new Date(2018, 2, 1),
      new Date(2018, 3, 1),
      new Date(2018, 4, 31),
    ];
    const timeframe = getTimeframeWindowFrom(startDate, 5);

    expect(timeframe.length).toBe(5);
    timeframe.forEach((timeframeItem, index) => {
      expect(timeframeItem.getFullYear()).toBe(mockTimeframe[index].getFullYear());
      expect(timeframeItem.getMonth()).toBe(mockTimeframe[index].getMonth());
      expect(timeframeItem.getDate()).toBe(mockTimeframe[index].getDate());
    });
  });

  it('returns array of date objects upto provided length (negative number) into the past starting from provided startDate', () => {
    const startDate = new Date(2018, 0, 1);
    const mockTimeframe = [
      new Date(2018, 0, 1),
      new Date(2017, 11, 1),
      new Date(2017, 10, 1),
      new Date(2017, 9, 1),
      new Date(2017, 8, 1),
    ];
    const timeframe = getTimeframeWindowFrom(startDate, -5);

    expect(timeframe.length).toBe(5);
    timeframe.forEach((timeframeItem, index) => {
      expect(timeframeItem.getFullYear()).toBe(mockTimeframe[index].getFullYear());
      expect(timeframeItem.getMonth()).toBe(mockTimeframe[index].getMonth());
      expect(timeframeItem.getDate()).toBe(mockTimeframe[index].getDate());
    });
  });
});

describe('calculateRemainingMilliseconds', () => {
  beforeEach(() => {
    jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
  });

  it('calculates the remaining time for a given end date', () => {
    const milliseconds = calculateRemainingMilliseconds('2063-04-04T01:44:03Z');

    expect(milliseconds).toBe(3723000);
  });

  it('returns 0 if the end date has passed', () => {
    const milliseconds = calculateRemainingMilliseconds('2063-04-03T00:00:00Z');

    expect(milliseconds).toBe(0);
  });
});

describe('cloneDate', () => {
  it('returns new date instance from existing date instance', () => {
    const initialDate = new Date(2019, 0, 1);
    const copiedDate = cloneDate(initialDate);

    expect(copiedDate.getTime()).toBe(initialDate.getTime());

    initialDate.setMonth(initialDate.getMonth() + 1);

    expect(copiedDate.getTime()).not.toBe(initialDate.getTime());
  });

  it('returns date instance when provided date param is not of type date or is undefined', () => {
    const initialDate = cloneDate();

    expect(initialDate instanceof Date).toBe(true);
  });
});

describe('getDateInPast', () => {
  const date = new Date('2019-07-16T00:00:00.000Z');
  const daysInPast = 90;

  it('returns the correct date in the past', () => {
    const dateInPast = getDateInPast(date, daysInPast);
    const expectedDateInPast = new Date('2019-04-17T00:00:00.000Z');

    expect(dateInPast).toStrictEqual(expectedDateInPast);
  });

  it('does not modifiy the original date', () => {
    getDateInPast(date, daysInPast);
    expect(date).toStrictEqual(new Date('2019-07-16T00:00:00.000Z'));
  });
});

describe('getDateInFuture', () => {
  const date = new Date('2019-07-16T00:00:00.000Z');
  const daysInFuture = 90;

  it('returns the correct date in the future', () => {
    const dateInFuture = getDateInFuture(date, daysInFuture);
    const expectedDateInFuture = new Date('2019-10-14T00:00:00.000Z');

    expect(dateInFuture).toStrictEqual(expectedDateInFuture);
  });

  it('does not modifiy the original date', () => {
    getDateInFuture(date, daysInFuture);
    expect(date).toStrictEqual(new Date('2019-07-16T00:00:00.000Z'));
  });
});

describe('isValidDate', () => {
  it.each`
    valueToCheck                              | isValid
    ${new Date()}                             | ${true}
    ${new Date('December 17, 1995 03:24:00')} | ${true}
    ${new Date('1995-12-17T03:24:00')}        | ${true}
    ${new Date('foo')}                        | ${false}
    ${5}                                      | ${false}
    ${''}                                     | ${false}
    ${false}                                  | ${false}
    ${undefined}                              | ${false}
    ${null}                                   | ${false}
  `('returns $expectedReturnValue when called with $dateToCheck', ({ valueToCheck, isValid }) => {
    expect(isValidDate(valueToCheck)).toBe(isValid);
  });
});

describe('getDatesInRange', () => {
  it('returns an empty array if 1st or 2nd argument is not a Date object', () => {
    const d1 = new Date('2019-01-01');
    const d2 = 90;
    const range = getDatesInRange(d1, d2);

    expect(range).toEqual([]);
  });

  it('returns a range of dates between two given dates', () => {
    const d1 = new Date('2019-01-01');
    const d2 = new Date('2019-01-31');

    const range = getDatesInRange(d1, d2);

    expect(range.length).toEqual(31);
  });

  it('applies mapper function if provided fro each item in range', () => {
    const d1 = new Date('2019-01-01');
    const d2 = new Date('2019-01-31');
    const formatter = (date) => date.getDate();

    const range = getDatesInRange(d1, d2, formatter);

    range.forEach((formattedItem, index) => {
      expect(formattedItem).toEqual(index + 1);
    });
  });
});

describe('secondsToMilliseconds', () => {
  it('converts seconds to milliseconds correctly', () => {
    expect(secondsToMilliseconds(0)).toBe(0);
    expect(secondsToMilliseconds(60)).toBe(60000);
    expect(secondsToMilliseconds(123)).toBe(123000);
  });
});

describe('secondsToDays', () => {
  it('converts seconds to days correctly', () => {
    expect(secondsToDays(0)).toBe(0);
    expect(secondsToDays(90000)).toBe(1);
    expect(secondsToDays(270000)).toBe(3);
  });
});

describe('date addition/subtraction methods', () => {
  beforeEach(() => {
    timezoneMock.register('US/Eastern');
  });

  afterEach(() => {
    timezoneMock.unregister();
  });

  describe('dayAfter', () => {
    const input = '2019-03-10T00:00:00.000Z';
    const expectedLocalResult = '2019-03-10T23:00:00.000Z';
    const expectedUTCResult = '2019-03-11T00:00:00.000Z';

    it.each`
      inputAsString | options           | expectedAsString
      ${input}      | ${undefined}      | ${expectedLocalResult}
      ${input}      | ${{}}             | ${expectedLocalResult}
      ${input}      | ${{ utc: false }} | ${expectedLocalResult}
      ${input}      | ${{ utc: true }}  | ${expectedUTCResult}
    `(
      'when the provided date is $inputAsString and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = dayAfter(inputDate, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );

    it('does not modifiy the original date', () => {
      const inputDate = new Date(input);
      dayAfter(inputDate);
      expect(inputDate.toISOString()).toBe(input);
    });
  });

  describe('nDaysAfter', () => {
    const input = '2019-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfDays | options           | expectedAsString
      ${input}      | ${1}         | ${undefined}      | ${'2019-07-17T00:00:00.000Z'}
      ${input}      | ${-1}        | ${undefined}      | ${'2019-07-15T00:00:00.000Z'}
      ${input}      | ${0}         | ${undefined}      | ${'2019-07-16T00:00:00.000Z'}
      ${input}      | ${0.9}       | ${undefined}      | ${'2019-07-16T00:00:00.000Z'}
      ${input}      | ${120}       | ${undefined}      | ${'2019-11-13T01:00:00.000Z'}
      ${input}      | ${120}       | ${{}}             | ${'2019-11-13T01:00:00.000Z'}
      ${input}      | ${120}       | ${{ utc: false }} | ${'2019-11-13T01:00:00.000Z'}
      ${input}      | ${120}       | ${{ utc: true }}  | ${'2019-11-13T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfDays is $numberOfDays, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfDays, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = nDaysAfter(inputDate, numberOfDays, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nDaysBefore', () => {
    const input = '2019-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfDays | options           | expectedAsString
      ${input}      | ${1}         | ${undefined}      | ${'2019-07-15T00:00:00.000Z'}
      ${input}      | ${-1}        | ${undefined}      | ${'2019-07-17T00:00:00.000Z'}
      ${input}      | ${0}         | ${undefined}      | ${'2019-07-16T00:00:00.000Z'}
      ${input}      | ${0.9}       | ${undefined}      | ${'2019-07-15T00:00:00.000Z'}
      ${input}      | ${180}       | ${undefined}      | ${'2019-01-17T01:00:00.000Z'}
      ${input}      | ${180}       | ${{}}             | ${'2019-01-17T01:00:00.000Z'}
      ${input}      | ${180}       | ${{ utc: false }} | ${'2019-01-17T01:00:00.000Z'}
      ${input}      | ${180}       | ${{ utc: true }}  | ${'2019-01-17T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfDays is $numberOfDays, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfDays, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = nDaysBefore(inputDate, numberOfDays, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nHoursAfter', () => {
    const input = '2024-12-23T00:00:00.000Z';

    it.each`
      inputAsString | numberOfHours | expectedAsString
      ${input}      | ${1}          | ${'2024-12-23T01:00:00.000Z'}
      ${input}      | ${3}          | ${'2024-12-23T03:00:00.000Z'}
      ${input}      | ${-1}         | ${'2024-12-22T23:00:00.000Z'}
      ${input}      | ${0}          | ${'2024-12-23T00:00:00.000Z'}
      ${input}      | ${0.6}        | ${'2024-12-23T00:00:00.000Z'}
      ${input}      | ${18}         | ${'2024-12-23T18:00:00.000Z'}
      ${input}      | ${48}         | ${'2024-12-25T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfHours is $numberOfHours, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfHours, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = nHoursAfter(inputDate, numberOfHours);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nWeeksAfter', () => {
    const input = '2021-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfWeeks | options           | expectedAsString
      ${input}      | ${1}          | ${undefined}      | ${'2021-07-23T00:00:00.000Z'}
      ${input}      | ${3}          | ${undefined}      | ${'2021-08-06T00:00:00.000Z'}
      ${input}      | ${-1}         | ${undefined}      | ${'2021-07-09T00:00:00.000Z'}
      ${input}      | ${0}          | ${undefined}      | ${'2021-07-16T00:00:00.000Z'}
      ${input}      | ${0.6}        | ${undefined}      | ${'2021-07-20T00:00:00.000Z'}
      ${input}      | ${18}         | ${undefined}      | ${'2021-11-19T01:00:00.000Z'}
      ${input}      | ${18}         | ${{}}             | ${'2021-11-19T01:00:00.000Z'}
      ${input}      | ${18}         | ${{ utc: false }} | ${'2021-11-19T01:00:00.000Z'}
      ${input}      | ${18}         | ${{ utc: true }}  | ${'2021-11-19T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfWeeks is $numberOfWeeks, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfWeeks, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = nWeeksAfter(inputDate, numberOfWeeks, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nWeeksBefore', () => {
    const input = '2021-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfWeeks | options           | expectedAsString
      ${input}      | ${1}          | ${undefined}      | ${'2021-07-09T00:00:00.000Z'}
      ${input}      | ${3}          | ${undefined}      | ${'2021-06-25T00:00:00.000Z'}
      ${input}      | ${-1}         | ${undefined}      | ${'2021-07-23T00:00:00.000Z'}
      ${input}      | ${0}          | ${undefined}      | ${'2021-07-16T00:00:00.000Z'}
      ${input}      | ${0.6}        | ${undefined}      | ${'2021-07-11T00:00:00.000Z'}
      ${input}      | ${20}         | ${undefined}      | ${'2021-02-26T01:00:00.000Z'}
      ${input}      | ${20}         | ${{}}             | ${'2021-02-26T01:00:00.000Z'}
      ${input}      | ${20}         | ${{ utc: false }} | ${'2021-02-26T01:00:00.000Z'}
      ${input}      | ${20}         | ${{ utc: true }}  | ${'2021-02-26T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfWeeks is $numberOfWeeks, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfWeeks, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = nWeeksBefore(inputDate, numberOfWeeks, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nMonthsAfter', () => {
    // February has 28 days
    const feb2019 = '2019-02-15T00:00:00.000Z';
    // Except in 2020, it had 29 days
    const feb2020 = '2020-02-15T00:00:00.000Z';
    // April has 30 days
    const apr2020 = '2020-04-15T00:00:00.000Z';
    // May has 31 days
    const may2020 = '2020-05-15T00:00:00.000Z';
    // November 1, 2020 was the day Daylight Saving Time ended in 2020 (in the US)
    const oct2020 = '2020-10-15T00:00:00.000Z';

    it.each`
      inputAsString | numberOfMonths | options           | expectedAsString
      ${feb2019}    | ${1}           | ${undefined}      | ${'2019-03-14T23:00:00.000Z'}
      ${feb2020}    | ${1}           | ${undefined}      | ${'2020-03-14T23:00:00.000Z'}
      ${apr2020}    | ${1}           | ${undefined}      | ${'2020-05-15T00:00:00.000Z'}
      ${may2020}    | ${1}           | ${undefined}      | ${'2020-06-15T00:00:00.000Z'}
      ${may2020}    | ${12}          | ${undefined}      | ${'2021-05-15T00:00:00.000Z'}
      ${may2020}    | ${-1}          | ${undefined}      | ${'2020-04-15T00:00:00.000Z'}
      ${may2020}    | ${0}           | ${undefined}      | ${may2020}
      ${may2020}    | ${0.9}         | ${undefined}      | ${may2020}
      ${oct2020}    | ${1}           | ${undefined}      | ${'2020-11-15T01:00:00.000Z'}
      ${oct2020}    | ${1}           | ${{}}             | ${'2020-11-15T01:00:00.000Z'}
      ${oct2020}    | ${1}           | ${{ utc: false }} | ${'2020-11-15T01:00:00.000Z'}
      ${oct2020}    | ${1}           | ${{ utc: true }}  | ${'2020-11-15T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfMonths is $numberOfMonths, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfMonths, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = nMonthsAfter(inputDate, numberOfMonths, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  // NOTE: 2024-02-29 is a leap day
  describe('nYearsAfter', () => {
    it.each`
      date            | numberOfYears | expected
      ${'2020-07-06'} | ${1}          | ${'2021-07-06'}
      ${'2020-07-06'} | ${15}         | ${'2035-07-06'}
      ${'2024-03-02'} | ${1}          | ${'2025-03-02'}
      ${'2024-03-01'} | ${1}          | ${'2025-03-01'}
      ${'2024-02-29'} | ${1}          | ${'2025-02-28'}
      ${'2024-02-28'} | ${1}          | ${'2025-02-28'}
    `(
      'returns $expected for "$numberOfYears year(s) after $date"',
      ({ date, numberOfYears, expected }) => {
        expect(nYearsAfter(new Date(date), numberOfYears)).toEqual(new Date(expected));
      },
    );
  });

  describe('nYearsBefore', () => {
    it.each`
      date            | numberOfYears | expected
      ${'2020-07-06'} | ${4}          | ${'2016-07-06'}
      ${'2020-07-06'} | ${1}          | ${'2019-07-06'}
      ${'2024-03-02'} | ${1}          | ${'2023-03-02'}
      ${'2024-03-01'} | ${1}          | ${'2023-03-01'}
      ${'2024-02-29'} | ${1}          | ${'2023-02-28'}
      ${'2024-02-28'} | ${1}          | ${'2023-02-28'}
    `(
      'returns $expected for "$numberOfYears year(s) before $date"',
      ({ date, numberOfYears, expected }) => {
        expect(nYearsBefore(new Date(date), numberOfYears)).toEqual(new Date(expected));
      },
    );
  });

  describe('nMonthsBefore', () => {
    // The previous month (February) has 28 days
    const march2019 = '2019-03-15T00:00:00.000Z';
    // Except in 2020, it had 29 days
    const march2020 = '2020-03-15T00:00:00.000Z';
    // The previous month (April) has 30 days
    const may2020 = '2020-05-15T00:00:00.000Z';
    // The previous month (May) has 31 days
    const june2020 = '2020-06-15T00:00:00.000Z';
    // November 1, 2020 was the day Daylight Saving Time ended in 2020 (in the US)
    const nov2020 = '2020-11-15T00:00:00.000Z';

    it.each`
      inputAsString | numberOfMonths | options           | expectedAsString
      ${march2019}  | ${1}           | ${undefined}      | ${'2019-02-15T01:00:00.000Z'}
      ${march2020}  | ${1}           | ${undefined}      | ${'2020-02-15T01:00:00.000Z'}
      ${may2020}    | ${1}           | ${undefined}      | ${'2020-04-15T00:00:00.000Z'}
      ${june2020}   | ${1}           | ${undefined}      | ${'2020-05-15T00:00:00.000Z'}
      ${june2020}   | ${12}          | ${undefined}      | ${'2019-06-15T00:00:00.000Z'}
      ${june2020}   | ${-1}          | ${undefined}      | ${'2020-07-15T00:00:00.000Z'}
      ${june2020}   | ${0}           | ${undefined}      | ${june2020}
      ${june2020}   | ${0.9}         | ${undefined}      | ${'2020-05-15T00:00:00.000Z'}
      ${nov2020}    | ${1}           | ${undefined}      | ${'2020-10-14T23:00:00.000Z'}
      ${nov2020}    | ${1}           | ${{}}             | ${'2020-10-14T23:00:00.000Z'}
      ${nov2020}    | ${1}           | ${{ utc: false }} | ${'2020-10-14T23:00:00.000Z'}
      ${nov2020}    | ${1}           | ${{ utc: true }}  | ${'2020-10-15T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfMonths is $numberOfMonths, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfMonths, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = nMonthsBefore(inputDate, numberOfMonths, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });
});

describe('approximateDuration', () => {
  it.each`
    seconds
    ${null}
    ${{}}
    ${[]}
    ${-1}
  `('returns a blank string for seconds=$seconds', ({ seconds }) => {
    expect(approximateDuration(seconds)).toBe('');
  });

  it.each`
    seconds   | approximation
    ${0}      | ${'less than a minute'}
    ${25}     | ${'less than a minute'}
    ${45}     | ${'1 minute'}
    ${90}     | ${'1 minute'}
    ${100}    | ${'1 minute'}
    ${150}    | ${'2 minutes'}
    ${220}    | ${'3 minutes'}
    ${3000}   | ${'about 1 hour'}
    ${30000}  | ${'about 8 hours'}
    ${100000} | ${'1 day'}
    ${180000} | ${'2 days'}
  `('converts $seconds seconds to $approximation', ({ seconds, approximation }) => {
    expect(approximateDuration(seconds)).toBe(approximation);
  });
});

describe('differenceInSeconds', () => {
  const startDateTime = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    startDate                               | endDate                                 | expected
    ${startDateTime}                        | ${new Date('2019-07-17T00:00:00.000Z')} | ${0}
    ${startDateTime}                        | ${new Date('2019-07-17T12:00:00.000Z')} | ${43200}
    ${startDateTime}                        | ${new Date('2019-07-18T00:00:00.000Z')} | ${86400}
    ${new Date('2019-07-18T00:00:00.000Z')} | ${startDateTime}                        | ${-86400}
  `('returns $expected for $endDate - $startDate', ({ startDate, endDate, expected }) => {
    expect(differenceInSeconds(startDate, endDate)).toBe(expected);
  });
});

describe('differenceInMonths', () => {
  const startDateTime = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    startDate                               | endDate                                 | expected
    ${startDateTime}                        | ${startDateTime}                        | ${0}
    ${startDateTime}                        | ${new Date('2019-12-17T12:00:00.000Z')} | ${5}
    ${startDateTime}                        | ${new Date('2021-02-18T00:00:00.000Z')} | ${19}
    ${new Date('2021-02-18T00:00:00.000Z')} | ${startDateTime}                        | ${-19}
  `('returns $expected for $endDate - $startDate', ({ startDate, endDate, expected }) => {
    expect(differenceInMonths(startDate, endDate)).toBe(expected);
  });
});

describe('differenceInMilliseconds', () => {
  const startDateTime = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    startDate                               | endDate                                           | expected
    ${startDateTime.getTime()}              | ${new Date('2019-07-17T00:00:00.000Z')}           | ${0}
    ${startDateTime}                        | ${new Date('2019-07-17T12:00:00.000Z').getTime()} | ${43200000}
    ${startDateTime}                        | ${new Date('2019-07-18T00:00:00.000Z').getTime()} | ${86400000}
    ${new Date('2019-07-18T00:00:00.000Z')} | ${startDateTime.getTime()}                        | ${-86400000}
  `('returns $expected for $endDate - $startDate', ({ startDate, endDate, expected }) => {
    expect(differenceInMilliseconds(startDate, endDate)).toBe(expected);
  });
});

describe('dateAtFirstDayOfMonth', () => {
  const date = new Date('2019-07-16T12:00:00.000Z');

  it('returns the date at the first day of the month', () => {
    const startDate = dateAtFirstDayOfMonth(date);
    const expectedStartDate = new Date('2019-07-01T12:00:00.000Z');

    expect(startDate).toStrictEqual(expectedStartDate);
  });
});

describe('datesMatch', () => {
  const date = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    date1   | date2                                   | expected
    ${date} | ${new Date('2019-07-17T00:00:00.000Z')} | ${true}
    ${date} | ${new Date('2019-07-17T12:00:00.000Z')} | ${false}
  `('returns $expected for $date1 matches $date2', ({ date1, date2, expected }) => {
    expect(datesMatch(date1, date2)).toBe(expected);
  });
});

describe('format24HourTimeStringFromInt', () => {
  const expectedFormattedTimes = [
    [0, '00:00'],
    [2, '02:00'],
    [6, '06:00'],
    [9, '09:00'],
    [10, '10:00'],
    [16, '16:00'],
    [22, '22:00'],
    [32, ''],
    [NaN, ''],
    ['Invalid Int', ''],
    [null, ''],
    [undefined, ''],
  ];

  expectedFormattedTimes.forEach(([timeInt, expectedTimeStringIn24HourNotation]) => {
    it(`formats ${timeInt} as ${expectedTimeStringIn24HourNotation}`, () => {
      expect(format24HourTimeStringFromInt(timeInt)).toBe(expectedTimeStringIn24HourNotation);
    });
  });
});

describe('isInPast', () => {
  it.each`
    date                                   | expected
    ${new Date('2024-12-15')}              | ${false}
    ${new Date('2020-07-06T00:00')}        | ${false}
    ${new Date('2020-07-05T23:59:59.999')} | ${true}
    ${new Date('2020-07-05')}              | ${true}
    ${new Date('1999-03-21')}              | ${true}
  `('returns $expected for $date', ({ date, expected }) => {
    expect(isInPast(date)).toBe(expected);
  });
});

describe('isInFuture', () => {
  it.each`
    date                                   | expected
    ${new Date('2024-12-15')}              | ${true}
    ${new Date('2020-07-07T00:00')}        | ${true}
    ${new Date('2020-07-06T23:59:59.999')} | ${false}
    ${new Date('2020-07-06')}              | ${false}
    ${new Date('1999-03-21')}              | ${false}
  `('returns $expected for $date', ({ date, expected }) => {
    expect(isInFuture(date)).toBe(expected);
  });
});

describe('fallsBefore', () => {
  it.each`
    dateA                                  | dateB                                  | expected
    ${new Date('2020-07-06T23:59:59.999')} | ${new Date('2020-07-07T00:00')}        | ${true}
    ${new Date('2020-07-07T00:00')}        | ${new Date('2020-07-06T23:59:59.999')} | ${false}
    ${new Date('2020-04-04')}              | ${new Date('2021-10-10')}              | ${true}
    ${new Date('2021-10-10')}              | ${new Date('2020-04-04')}              | ${false}
  `('returns $expected for "$dateA falls before $dateB"', ({ dateA, dateB, expected }) => {
    expect(fallsBefore(dateA, dateB)).toBe(expected);
  });
});

describe('removeTime', () => {
  it.each`
    date                                   | expected
    ${new Date('2020-07-07')}              | ${new Date('2020-07-07T00:00:00.000')}
    ${new Date('2020-07-07T00:00:00.001')} | ${new Date('2020-07-07T00:00:00.000')}
    ${new Date('2020-07-07T23:59:59.999')} | ${new Date('2020-07-07T00:00:00.000')}
    ${new Date('2020-07-07T12:34:56.789')} | ${new Date('2020-07-07T00:00:00.000')}
  `('returns $expected for $date', ({ date, expected }) => {
    expect(removeTime(date)).toEqual(expected);
  });
});

describe('getTimeRemainingInWords', () => {
  it.each`
    date                                   | expected
    ${new Date('2020-07-06T12:34:56.789')} | ${'0 days remaining'}
    ${new Date('2020-07-07T12:34:56.789')} | ${'1 day remaining'}
    ${new Date('2020-07-08T12:34:56.789')} | ${'2 days remaining'}
    ${new Date('2020-07-12T12:34:56.789')} | ${'6 days remaining'}
    ${new Date('2020-07-13T12:34:56.789')} | ${'1 week remaining'}
    ${new Date('2020-07-19T12:34:56.789')} | ${'1 week remaining'}
    ${new Date('2020-07-20T12:34:56.789')} | ${'2 weeks remaining'}
    ${new Date('2020-07-27T12:34:56.789')} | ${'3 weeks remaining'}
    ${new Date('2020-08-03T12:34:56.789')} | ${'4 weeks remaining'}
    ${new Date('2020-08-05T12:34:56.789')} | ${'4 weeks remaining'}
    ${new Date('2020-08-06T12:34:56.789')} | ${'1 month remaining'}
    ${new Date('2020-09-06T12:34:56.789')} | ${'2 months remaining'}
    ${new Date('2021-06-06T12:34:56.789')} | ${'11 months remaining'}
    ${new Date('2021-07-06T12:34:56.789')} | ${'1 year remaining'}
    ${new Date('2022-07-06T12:34:56.789')} | ${'2 years remaining'}
    ${new Date('2030-07-06T12:34:56.789')} | ${'10 years remaining'}
    ${new Date('2119-07-06T12:34:56.789')} | ${'99 years remaining'}
  `('returns $expected for $date', ({ date, expected }) => {
    expect(getTimeRemainingInWords(date)).toEqual(expected);
  });
});

describe('getStartOfDay', () => {
  beforeEach(() => {
    timezoneMock.register('US/Eastern');
  });

  afterEach(() => {
    timezoneMock.unregister();
  });

  it.each`
    inputAsString                      | options           | expectedAsString
    ${'2021-01-29T18:08:23.014Z'}      | ${undefined}      | ${'2021-01-29T05:00:00.000Z'}
    ${'2021-01-29T13:08:23.014-05:00'} | ${undefined}      | ${'2021-01-29T05:00:00.000Z'}
    ${'2021-01-30T03:08:23.014+09:00'} | ${undefined}      | ${'2021-01-29T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${undefined}      | ${'2021-01-28T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{}}             | ${'2021-01-28T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{ utc: false }} | ${'2021-01-28T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{ utc: true }}  | ${'2021-01-29T00:00:00.000Z'}
  `(
    'when the provided date is $inputAsString and the options parameter is $options, returns $expectedAsString',
    ({ inputAsString, options, expectedAsString }) => {
      const inputDate = new Date(inputAsString);
      const actual = getStartOfDay(inputDate, options);

      expect(actual.toISOString()).toEqual(expectedAsString);
    },
  );
});

describe('getStartOfWeek', () => {
  beforeEach(() => {
    timezoneMock.register('US/Eastern');
  });

  afterEach(() => {
    timezoneMock.unregister();
  });

  it.each`
    inputAsString                      | options           | expectedAsString
    ${'2021-01-29T18:08:23.014Z'}      | ${undefined}      | ${'2021-01-25T05:00:00.000Z'}
    ${'2021-01-29T13:08:23.014-05:00'} | ${undefined}      | ${'2021-01-25T05:00:00.000Z'}
    ${'2021-01-30T03:08:23.014+09:00'} | ${undefined}      | ${'2021-01-25T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${undefined}      | ${'2021-01-25T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{}}             | ${'2021-01-25T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{ utc: false }} | ${'2021-01-25T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{ utc: true }}  | ${'2021-01-26T00:00:00.000Z'}
  `(
    'when the provided date is $inputAsString and the options parameter is $options, returns $expectedAsString',
    ({ inputAsString, options, expectedAsString }) => {
      const inputDate = new Date(inputAsString);
      const actual = getStartOfWeek(inputDate, options);

      expect(actual.toISOString()).toEqual(expectedAsString);
    },
  );
});

describe('daysToSeconds', () => {
  it('converts days to seconds correctly', () => {
    expect(daysToSeconds(0)).toBe(0);
    expect(daysToSeconds(0.1)).toBe(8640);
    expect(daysToSeconds(0.5)).toBe(43200);
    expect(daysToSeconds(1)).toBe(86400);
    expect(daysToSeconds(2.5)).toBe(216000);
    expect(daysToSeconds(3)).toBe(259200);
    expect(daysToSeconds(5)).toBe(432000);
  });
});
