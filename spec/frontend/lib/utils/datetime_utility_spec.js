import { __, s__ } from '~/locale';
import * as datetimeUtility from '~/lib/utils/datetime_utility';

describe('Date time utils', () => {
  describe('timeFor', () => {
    it('returns localize `past due` when in past', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() - 1);

      expect(datetimeUtility.timeFor(date)).toBe(s__('Timeago|Past due'));
    });

    it('returns localized remaining time when in the future', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() + 1);

      // Add a day to prevent a transient error. If date is even 1 second
      // short of a full year, timeFor will return '11 months remaining'
      date.setDate(date.getDate() + 1);

      expect(datetimeUtility.timeFor(date)).toBe(s__('Timeago|1 year remaining'));
    });
  });

  describe('get localized day name', () => {
    it('should return Sunday', () => {
      const day = datetimeUtility.getDayName(new Date('07/17/2016'));

      expect(day).toBe(__('Sunday'));
    });

    it('should return Monday', () => {
      const day = datetimeUtility.getDayName(new Date('07/18/2016'));

      expect(day).toBe(__('Monday'));
    });

    it('should return Tuesday', () => {
      const day = datetimeUtility.getDayName(new Date('07/19/2016'));

      expect(day).toBe(__('Tuesday'));
    });

    it('should return Wednesday', () => {
      const day = datetimeUtility.getDayName(new Date('07/20/2016'));

      expect(day).toBe(__('Wednesday'));
    });

    it('should return Thursday', () => {
      const day = datetimeUtility.getDayName(new Date('07/21/2016'));

      expect(day).toBe(__('Thursday'));
    });

    it('should return Friday', () => {
      const day = datetimeUtility.getDayName(new Date('07/22/2016'));

      expect(day).toBe(__('Friday'));
    });

    it('should return Saturday', () => {
      const day = datetimeUtility.getDayName(new Date('07/23/2016'));

      expect(day).toBe(__('Saturday'));
    });
  });

  describe('formatDate', () => {
    it('should format date properly', () => {
      const formattedDate = datetimeUtility.formatDate(new Date('07/23/2016'));

      expect(formattedDate).toBe('Jul 23, 2016 12:00am GMT+0000');
    });

    it('should format ISO date properly', () => {
      const formattedDate = datetimeUtility.formatDate('2016-07-23T00:00:00.559Z');

      expect(formattedDate).toBe('Jul 23, 2016 12:00am GMT+0000');
    });

    it('should throw an error if date is invalid', () => {
      expect(() => {
        datetimeUtility.formatDate('2016-07-23 00:00:00 UTC');
      }).toThrow(new Error('Invalid date'));
    });
  });

  describe('get day difference', () => {
    it('should return 7', () => {
      const firstDay = new Date('07/01/2016');
      const secondDay = new Date('07/08/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);

      expect(difference).toBe(7);
    });

    it('should return 31', () => {
      const firstDay = new Date('07/01/2016');
      const secondDay = new Date('08/01/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);

      expect(difference).toBe(31);
    });

    it('should return 365', () => {
      const firstDay = new Date('07/02/2015');
      const secondDay = new Date('07/01/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);

      expect(difference).toBe(365);
    });
  });
});

describe('timeIntervalInWords', () => {
  it('should return string with number of minutes and seconds', () => {
    expect(datetimeUtility.timeIntervalInWords(9.54)).toEqual(s__('Timeago|9 seconds'));
    expect(datetimeUtility.timeIntervalInWords(1)).toEqual(s__('Timeago|1 second'));
    expect(datetimeUtility.timeIntervalInWords(200)).toEqual(s__('Timeago|3 minutes 20 seconds'));
    expect(datetimeUtility.timeIntervalInWords(6008)).toEqual(s__('Timeago|100 minutes 8 seconds'));
  });
});

describe('dateInWords', () => {
  const date = new Date('07/01/2016');

  it('should return date in words', () => {
    expect(datetimeUtility.dateInWords(date)).toEqual(s__('July 1, 2016'));
  });

  it('should return abbreviated month name', () => {
    expect(datetimeUtility.dateInWords(date, true)).toEqual(s__('Jul 1, 2016'));
  });

  it('should return date in words without year', () => {
    expect(datetimeUtility.dateInWords(date, true, true)).toEqual(s__('Jul 1'));
  });
});

describe('monthInWords', () => {
  const date = new Date('2017-01-20');

  it('returns month name from provided date', () => {
    expect(datetimeUtility.monthInWords(date)).toBe(s__('January'));
  });

  it('returns abbreviated month name from provided date', () => {
    expect(datetimeUtility.monthInWords(date, true)).toBe(s__('Jan'));
  });
});

describe('totalDaysInMonth', () => {
  it('returns number of days in a month for given date', () => {
    // 1st Feb, 2016 (leap year)
    expect(datetimeUtility.totalDaysInMonth(new Date(2016, 1, 1))).toBe(29);

    // 1st Feb, 2017
    expect(datetimeUtility.totalDaysInMonth(new Date(2017, 1, 1))).toBe(28);

    // 1st Jan, 2017
    expect(datetimeUtility.totalDaysInMonth(new Date(2017, 0, 1))).toBe(31);
  });
});

describe('getSundays', () => {
  it('returns array of dates representing all Sundays of the month', () => {
    // December, 2017 (it has 5 Sundays)
    const dateOfSundays = [3, 10, 17, 24, 31];
    const sundays = datetimeUtility.getSundays(new Date(2017, 11, 1));

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
    const timeframe = datetimeUtility.getTimeframeWindowFrom(startDate, 5);

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
    const timeframe = datetimeUtility.getTimeframeWindowFrom(startDate, -5);

    expect(timeframe.length).toBe(5);
    timeframe.forEach((timeframeItem, index) => {
      expect(timeframeItem.getFullYear()).toBe(mockTimeframe[index].getFullYear());
      expect(timeframeItem.getMonth()).toBe(mockTimeframe[index].getMonth());
      expect(timeframeItem.getDate()).toBe(mockTimeframe[index].getDate());
    });
  });
});

describe('formatTime', () => {
  const expectedTimestamps = [
    [0, '00:00:00'],
    [1000, '00:00:01'],
    [42000, '00:00:42'],
    [121000, '00:02:01'],
    [10921000, '03:02:01'],
    [108000000, '30:00:00'],
  ];

  expectedTimestamps.forEach(([milliseconds, expectedTimestamp]) => {
    it(`formats ${milliseconds}ms as ${expectedTimestamp}`, () => {
      expect(datetimeUtility.formatTime(milliseconds)).toBe(expectedTimestamp);
    });
  });
});

describe('datefix', () => {
  describe('pad', () => {
    it('should add a 0 when length is smaller than 2', () => {
      expect(datetimeUtility.pad(2)).toEqual('02');
    });

    it('should not add a zero when length matches the default', () => {
      expect(datetimeUtility.pad(12)).toEqual('12');
    });

    it('should add a 0 when length is smaller than the provided', () => {
      expect(datetimeUtility.pad(12, 3)).toEqual('012');
    });
  });

  describe('parsePikadayDate', () => {
    // removed because of https://gitlab.com/gitlab-org/gitlab-foss/issues/39834
  });

  describe('pikadayToString', () => {
    it('should format a UTC date into yyyy-mm-dd format', () => {
      expect(datetimeUtility.pikadayToString(new Date('2020-01-29:00:00'))).toEqual('2020-01-29');
    });
  });
});

describe('prettyTime methods', () => {
  const assertTimeUnits = (obj, minutes, hours, days, weeks) => {
    expect(obj.minutes).toBe(minutes);
    expect(obj.hours).toBe(hours);
    expect(obj.days).toBe(days);
    expect(obj.weeks).toBe(weeks);
  };

  describe('parseSeconds', () => {
    it('should correctly parse a negative value', () => {
      const zeroSeconds = datetimeUtility.parseSeconds(-1000);

      assertTimeUnits(zeroSeconds, 16, 0, 0, 0);
    });

    it('should correctly parse a zero value', () => {
      const zeroSeconds = datetimeUtility.parseSeconds(0);

      assertTimeUnits(zeroSeconds, 0, 0, 0, 0);
    });

    it('should correctly parse a small non-zero second values', () => {
      const subOneMinute = datetimeUtility.parseSeconds(10);
      const aboveOneMinute = datetimeUtility.parseSeconds(100);
      const manyMinutes = datetimeUtility.parseSeconds(1000);

      assertTimeUnits(subOneMinute, 0, 0, 0, 0);
      assertTimeUnits(aboveOneMinute, 1, 0, 0, 0);
      assertTimeUnits(manyMinutes, 16, 0, 0, 0);
    });

    it('should correctly parse large second values', () => {
      const aboveOneHour = datetimeUtility.parseSeconds(4800);
      const aboveOneDay = datetimeUtility.parseSeconds(110000);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 3, 173);
    });

    it('should correctly accept a custom param for hoursPerDay', () => {
      const config = { hoursPerDay: 24 };

      const aboveOneHour = datetimeUtility.parseSeconds(4800, config);
      const aboveOneDay = datetimeUtility.parseSeconds(110000, config);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 1, 0);
      assertTimeUnits(aboveOneWeek, 26, 8, 4, 57);
    });

    it('should correctly accept a custom param for daysPerWeek', () => {
      const config = { daysPerWeek: 7 };

      const aboveOneHour = datetimeUtility.parseSeconds(4800, config);
      const aboveOneDay = datetimeUtility.parseSeconds(110000, config);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 0, 124);
    });

    it('should correctly accept custom params for daysPerWeek and hoursPerDay', () => {
      const config = { daysPerWeek: 55, hoursPerDay: 14 };

      const aboveOneHour = datetimeUtility.parseSeconds(4800, config);
      const aboveOneDay = datetimeUtility.parseSeconds(110000, config);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 2, 2, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 1, 9);
    });

    it('should correctly parse values when limitedToHours is true', () => {
      const twoDays = datetimeUtility.parseSeconds(173000, { limitToHours: true });

      assertTimeUnits(twoDays, 3, 48, 0, 0);
    });
  });

  describe('stringifyTime', () => {
    it('should stringify values with all non-zero units', () => {
      const timeObject = {
        weeks: 1,
        days: 4,
        hours: 7,
        minutes: 20,
      };

      const timeString = datetimeUtility.stringifyTime(timeObject);

      expect(timeString).toBe('1w 4d 7h 20m');
    });

    it('should stringify values with some non-zero units', () => {
      const timeObject = {
        weeks: 0,
        days: 4,
        hours: 0,
        minutes: 20,
      };

      const timeString = datetimeUtility.stringifyTime(timeObject);

      expect(timeString).toBe('4d 20m');
    });

    it('should stringify values with no non-zero units', () => {
      const timeObject = {
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
      };

      const timeString = datetimeUtility.stringifyTime(timeObject);

      expect(timeString).toBe('0m');
    });

    it('should return non-condensed representation of time object', () => {
      const timeObject = { weeks: 1, days: 0, hours: 1, minutes: 0 };

      expect(datetimeUtility.stringifyTime(timeObject, true)).toEqual('1 week 1 hour');
    });
  });
});

describe('calculateRemainingMilliseconds', () => {
  beforeEach(() => {
    jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
  });

  it('calculates the remaining time for a given end date', () => {
    const milliseconds = datetimeUtility.calculateRemainingMilliseconds('2063-04-04T01:44:03Z');

    expect(milliseconds).toBe(3723000);
  });

  it('returns 0 if the end date has passed', () => {
    const milliseconds = datetimeUtility.calculateRemainingMilliseconds('2063-04-03T00:00:00Z');

    expect(milliseconds).toBe(0);
  });
});

describe('newDate', () => {
  it('returns new date instance from existing date instance', () => {
    const initialDate = new Date(2019, 0, 1);
    const copiedDate = datetimeUtility.newDate(initialDate);

    expect(copiedDate.getTime()).toBe(initialDate.getTime());

    initialDate.setMonth(initialDate.getMonth() + 1);

    expect(copiedDate.getTime()).not.toBe(initialDate.getTime());
  });

  it('returns date instance when provided date param is not of type date or is undefined', () => {
    const initialDate = datetimeUtility.newDate();

    expect(initialDate instanceof Date).toBe(true);
  });
});

describe('getDateInPast', () => {
  const date = new Date('2019-07-16T00:00:00.000Z');
  const daysInPast = 90;

  it('returns the correct date in the past', () => {
    const dateInPast = datetimeUtility.getDateInPast(date, daysInPast);
    const expectedDateInPast = new Date('2019-04-17T00:00:00.000Z');

    expect(dateInPast).toStrictEqual(expectedDateInPast);
  });

  it('does not modifiy the original date', () => {
    datetimeUtility.getDateInPast(date, daysInPast);
    expect(date).toStrictEqual(new Date('2019-07-16T00:00:00.000Z'));
  });
});

describe('getDatesInRange', () => {
  it('returns an empty array if 1st or 2nd argument is not a Date object', () => {
    const d1 = new Date('2019-01-01');
    const d2 = 90;
    const range = datetimeUtility.getDatesInRange(d1, d2);

    expect(range).toEqual([]);
  });

  it('returns a range of dates between two given dates', () => {
    const d1 = new Date('2019-01-01');
    const d2 = new Date('2019-01-31');

    const range = datetimeUtility.getDatesInRange(d1, d2);

    expect(range.length).toEqual(31);
  });

  it('applies mapper function if provided fro each item in range', () => {
    const d1 = new Date('2019-01-01');
    const d2 = new Date('2019-01-31');
    const formatter = date => date.getDate();

    const range = datetimeUtility.getDatesInRange(d1, d2, formatter);

    range.forEach((formattedItem, index) => {
      expect(formattedItem).toEqual(index + 1);
    });
  });
});

describe('secondsToMilliseconds', () => {
  it('converts seconds to milliseconds correctly', () => {
    expect(datetimeUtility.secondsToMilliseconds(0)).toBe(0);
    expect(datetimeUtility.secondsToMilliseconds(60)).toBe(60000);
    expect(datetimeUtility.secondsToMilliseconds(123)).toBe(123000);
  });
});

describe('dayAfter', () => {
  const date = new Date('2019-07-16T00:00:00.000Z');

  it('returns the following date', () => {
    const nextDay = datetimeUtility.dayAfter(date);
    const expectedNextDate = new Date('2019-07-17T00:00:00.000Z');

    expect(nextDay).toStrictEqual(expectedNextDate);
  });

  it('does not modifiy the original date', () => {
    datetimeUtility.dayAfter(date);
    expect(date).toStrictEqual(new Date('2019-07-16T00:00:00.000Z'));
  });
});

describe('secondsToDays', () => {
  it('converts seconds to days correctly', () => {
    expect(datetimeUtility.secondsToDays(0)).toBe(0);
    expect(datetimeUtility.secondsToDays(90000)).toBe(1);
    expect(datetimeUtility.secondsToDays(270000)).toBe(3);
  });
});
