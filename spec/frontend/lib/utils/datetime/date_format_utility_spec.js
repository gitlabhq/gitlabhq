import timezoneMock from 'timezone-mock';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import * as utils from '~/lib/utils/datetime/date_format_utility';

describe('date_format_utility.js', () => {
  describe('padWithZeros', () => {
    it.each`
      input    | output
      ${0}     | ${'00'}
      ${'1'}   | ${'01'}
      ${'10'}  | ${'10'}
      ${'100'} | ${'100'}
      ${100}   | ${'100'}
      ${'a'}   | ${'0a'}
      ${'foo'} | ${'foo'}
    `('properly pads $input to match $output', ({ input, output }) => {
      expect(utils.padWithZeros(input)).toEqual([output]);
    });

    it('accepts multiple arguments', () => {
      expect(utils.padWithZeros(1, '2', 3)).toEqual(['01', '02', '03']);
    });

    it('returns an empty array provided no argument', () => {
      expect(utils.padWithZeros()).toEqual([]);
    });
  });

  describe('stripTimezoneFromISODate', () => {
    it.each`
      input                          | expectedOutput
      ${'2021-08-16T00:00:00Z'}      | ${'2021-08-16T00:00:00'}
      ${'2021-08-16T10:30:00+02:00'} | ${'2021-08-16T10:30:00'}
      ${'2021-08-16T10:30:00-05:30'} | ${'2021-08-16T10:30:00'}
    `('returns $expectedOutput when given $input', ({ input, expectedOutput }) => {
      expect(utils.stripTimezoneFromISODate(input)).toBe(expectedOutput);
    });

    it('returns null if date is invalid', () => {
      expect(utils.stripTimezoneFromISODate('Invalid date')).toBe(null);
    });
  });

  describe('dateToYearMonthDate', () => {
    it.each`
      date                      | expectedOutput
      ${new Date('2021-08-05')} | ${{ year: '2021', month: '08', day: '05' }}
      ${new Date('2021-12-24')} | ${{ year: '2021', month: '12', day: '24' }}
    `('returns $expectedOutput provided $date', ({ date, expectedOutput }) => {
      expect(utils.dateToYearMonthDate(date)).toEqual(expectedOutput);
    });

    it('throws provided an invalid date', () => {
      expect(() => utils.dateToYearMonthDate('Invalid date')).toThrow(
        'Argument should be a Date instance',
      );
    });
  });

  describe('timeToHoursMinutes', () => {
    it.each`
      time       | expectedOutput
      ${'23:12'} | ${{ hours: '23', minutes: '12' }}
      ${'23:12'} | ${{ hours: '23', minutes: '12' }}
    `('returns $expectedOutput provided $time', ({ time, expectedOutput }) => {
      expect(utils.timeToHoursMinutes(time)).toEqual(expectedOutput);
    });

    it('throws provided an invalid time', () => {
      expect(() => utils.timeToHoursMinutes('Invalid time')).toThrow('Invalid time provided');
    });
  });

  describe('dateAndTimeToISOString', () => {
    it('computes the date properly', () => {
      expect(utils.dateAndTimeToISOString(new Date('2021-08-16'), '10:00')).toBe(
        '2021-08-16T10:00:00.000Z',
      );
    });

    it('computes the date properly with an offset', () => {
      expect(utils.dateAndTimeToISOString(new Date('2021-08-16'), '10:00', '-04:00')).toBe(
        '2021-08-16T10:00:00.000-04:00',
      );
    });

    it('throws if date in invalid', () => {
      expect(() => utils.dateAndTimeToISOString('Invalid date', '10:00')).toThrow(
        'Argument should be a Date instance',
      );
    });

    it('throws if time in invalid', () => {
      expect(() => utils.dateAndTimeToISOString(new Date('2021-08-16'), '')).toThrow(
        'Invalid time provided',
      );
    });

    it('throws if offset is invalid', () => {
      expect(() =>
        utils.dateAndTimeToISOString(new Date('2021-08-16'), '10:00', 'not an offset'),
      ).toThrow('Could not initialize date');
    });
  });

  describe('dateToTimeInputValue', () => {
    it.each`
      input                                        | expectedOutput
      ${new Date('2021-08-16T10:00:00.000Z')}      | ${'10:00'}
      ${new Date('2021-08-16T22:30:00.000Z')}      | ${'22:30'}
      ${new Date('2021-08-16T22:30:00.000-03:00')} | ${'01:30'}
    `('extracts $expectedOutput out of $input', ({ input, expectedOutput }) => {
      expect(utils.dateToTimeInputValue(input)).toBe(expectedOutput);
    });

    it('throws if date is invalid', () => {
      expect(() => utils.dateToTimeInputValue('Invalid date')).toThrow(
        'Argument should be a Date instance',
      );
    });
  });

  describe('formatTimeAsSummary', () => {
    it.each`
      unit         | value   | result
      ${'months'}  | ${1.5}  | ${'1.5 months'}
      ${'weeks'}   | ${1.25} | ${'1.5 weeks'}
      ${'days'}    | ${2}    | ${'2 days'}
      ${'hours'}   | ${10}   | ${'10 hours'}
      ${'minutes'} | ${20}   | ${'20 minutes'}
      ${'seconds'} | ${10}   | ${'<1 minute'}
      ${'seconds'} | ${0}    | ${'-'}
    `('will format $value $unit to $result', ({ unit, value, result }) => {
      expect(utils.formatTimeAsSummary({ [unit]: value })).toBe(result);
    });
  });

  describe('formatUtcOffset', () => {
    it.each`
      offset       | expected
      ${-32400}    | ${'-9'}
      ${'-12600'}  | ${'-3.5'}
      ${0}         | ${' 0'}
      ${'10800'}   | ${'+3'}
      ${19800}     | ${'+5.5'}
      ${0}         | ${' 0'}
      ${[]}        | ${' 0'}
      ${{}}        | ${' 0'}
      ${true}      | ${' 0'}
      ${null}      | ${' 0'}
      ${undefined} | ${' 0'}
    `('returns $expected given $offset', ({ offset, expected }) => {
      expect(utils.formatUtcOffset(offset)).toEqual(expected);
    });
  });

  describe('humanTimeframe', () => {
    it.each`
      startDate              | dueDate                 | returnValue
      ${newDate('2021-1-1')} | ${newDate('2021-2-28')} | ${'Jan 1 – Feb 28, 2021'}
      ${newDate('2021-1-1')} | ${newDate('2022-2-28')} | ${'Jan 1, 2021 – Feb 28, 2022'}
      ${newDate('2021-1-1')} | ${null}                 | ${'Jan 1, 2021 – No due date'}
      ${null}                | ${newDate('2021-2-28')} | ${'No start date – Feb 28, 2021'}
    `(
      'returns string "$returnValue" when startDate is $startDate and dueDate is $dueDate',
      ({ startDate, dueDate, returnValue }) => {
        expect(utils.humanTimeframe(startDate, dueDate)).toBe(returnValue);
      },
    );
  });

  describe('formatTimeSpent', () => {
    describe('with limitToHours false', () => {
      it('formats 34500 seconds to `1d 1h 35m`', () => {
        expect(utils.formatTimeSpent(34500)).toEqual('1d 1h 35m');
      });

      it('formats -34500 seconds to `- 1d 1h 35m`', () => {
        expect(utils.formatTimeSpent(-34500)).toEqual('- 1d 1h 35m');
      });
    });

    describe('with limitToHours true', () => {
      it('formats 34500 seconds to `9h 35m`', () => {
        expect(utils.formatTimeSpent(34500, true)).toEqual('9h 35m');
      });

      it('formats -34500 seconds to `- 9h 35m`', () => {
        expect(utils.formatTimeSpent(-34500, true)).toEqual('- 9h 35m');
      });
    });
  });

  describe('get localized day name', () => {
    it('should return Sunday', () => {
      const day = utils.getDayName(new Date('07/17/2016'));

      expect(day).toBe('Sunday');
    });

    it('should return Monday', () => {
      const day = utils.getDayName(new Date('07/18/2016'));

      expect(day).toBe('Monday');
    });

    it('should return Tuesday', () => {
      const day = utils.getDayName(new Date('07/19/2016'));

      expect(day).toBe('Tuesday');
    });

    it('should return Wednesday', () => {
      const day = utils.getDayName(new Date('07/20/2016'));

      expect(day).toBe('Wednesday');
    });

    it('should return Thursday', () => {
      const day = utils.getDayName(new Date('07/21/2016'));

      expect(day).toBe('Thursday');
    });

    it('should return Friday', () => {
      const day = utils.getDayName(new Date('07/22/2016'));

      expect(day).toBe('Friday');
    });

    it('should return Saturday', () => {
      const day = utils.getDayName(new Date('07/23/2016'));

      expect(day).toBe('Saturday');
    });
  });

  describe('formatDateAsMonth', () => {
    it('should format dash cased date properly', () => {
      const formattedMonth = utils.formatDateAsMonth(new Date('2020-06-28'));

      expect(formattedMonth).toBe('Jun');
    });

    it('should format return the non-abbreviated month', () => {
      const formattedMonth = utils.formatDateAsMonth(new Date('2020-07-28'), {
        abbreviated: false,
      });

      expect(formattedMonth).toBe('July');
    });

    it('should format date with slashes properly', () => {
      const formattedMonth = utils.formatDateAsMonth(new Date('07/23/2016'));

      expect(formattedMonth).toBe('Jul');
    });

    it('should format ISO date properly', () => {
      const formattedMonth = utils.formatDateAsMonth('2016-07-23T00:00:00.559Z');

      expect(formattedMonth).toBe('Jul');
    });
  });

  describe('formatDate', () => {
    it('should format date properly', () => {
      const formattedDate = utils.formatDate(new Date('07/23/2016'));

      expect(formattedDate).toBe('Jul 23, 2016 12:00am UTC');
    });

    it('should format ISO date properly', () => {
      const formattedDate = utils.formatDate('2016-07-23T00:00:00.559Z');

      expect(formattedDate).toBe('Jul 23, 2016 12:00am UTC');
    });

    it('should throw an error if date is invalid', () => {
      expect(() => {
        utils.formatDate('2016-07-23 00:00:00 UTC');
      }).toThrow(new Error('Invalid date'));
    });

    describe('convert local timezone to UTC with utc parameter', () => {
      const midnightUTC = '2020-07-09';
      const format = 'mmm d, yyyy';

      beforeEach(() => {
        timezoneMock.register('US/Pacific');
      });

      afterEach(() => {
        timezoneMock.unregister();
      });

      it('defaults to false', () => {
        const formattedDate = utils.formatDate(midnightUTC, format);

        expect(formattedDate).toBe('Jul 8, 2020');
      });

      it('converts local time to UTC if utc flag is true', () => {
        const formattedDate = utils.formatDate(midnightUTC, format, true);

        expect(formattedDate).toBe('Jul 9, 2020');
      });
    });
  });

  describe('timeIntervalInWords', () => {
    it('should return string with number of minutes and seconds', () => {
      expect(utils.timeIntervalInWords(9.54)).toEqual('9 seconds');
      expect(utils.timeIntervalInWords(1)).toEqual('1 second');
      expect(utils.timeIntervalInWords(200)).toEqual('3 minutes 20 seconds');
      expect(utils.timeIntervalInWords(6008)).toEqual('100 minutes 8 seconds');
    });
  });

  describe('humanizeTimeInterval', () => {
    describe.each`
      intervalInSeconds | expected         | abbreviated
      ${0}              | ${'0 seconds'}   | ${'0s'}
      ${1}              | ${'1 second'}    | ${'1s'}
      ${1.48}           | ${'1.5 seconds'} | ${'1.5s'}
      ${2}              | ${'2 seconds'}   | ${'2s'}
      ${60}             | ${'1 minute'}    | ${'1min'}
      ${91}             | ${'1.5 minutes'} | ${'1.5min'}
      ${120}            | ${'2 minutes'}   | ${'2min'}
      ${3600}           | ${'1 hour'}      | ${'1h'}
      ${5401}           | ${'1.5 hours'}   | ${'1.5h'}
      ${7200}           | ${'2 hours'}     | ${'2h'}
      ${86400}          | ${'1 day'}       | ${'1d'}
      ${129601}         | ${'1.5 days'}    | ${'1.5d'}
      ${172800}         | ${'2 days'}      | ${'2d'}
    `(
      'when the time interval is $intervalInSeconds seconds',
      ({ intervalInSeconds, expected, abbreviated }) => {
        it(`returns "${expected}" by default`, () => {
          expect(utils.humanizeTimeInterval(intervalInSeconds)).toBe(expected);
        });

        it(`returns "${abbreviated}" when rendering the abbreviated`, () => {
          expect(utils.humanizeTimeInterval(intervalInSeconds, { abbreviated: true })).toBe(
            abbreviated,
          );
        });
      },
    );
  });

  describe('monthInWords', () => {
    const date = new Date('2017-01-20');

    it('returns month name from provided date', () => {
      expect(utils.monthInWords(date)).toBe('January');
    });

    it('returns abbreviated month name from provided date', () => {
      expect(utils.monthInWords(date, true)).toBe('Jan');
    });
  });

  describe('formatTime', () => {
    it.each`
      milliseconds                            | expected
      ${0}                                    | ${'00:00:00'}
      ${1}                                    | ${'00:00:00'}
      ${499}                                  | ${'00:00:00'}
      ${500}                                  | ${'00:00:01'}
      ${1000}                                 | ${'00:00:01'}
      ${42 * 1000}                            | ${'00:00:42'}
      ${60 * 1000}                            | ${'00:01:00'}
      ${(60 + 1) * 1000}                      | ${'00:01:01'}
      ${(3 * 60 * 60 + 2 * 60 + 1) * 1000}    | ${'03:02:01'}
      ${(11 * 60 * 60 + 59 * 60 + 59) * 1000} | ${'11:59:59'}
      ${30 * 60 * 60 * 1000}                  | ${'30:00:00'}
      ${(35 * 60 * 60 + 3 * 60 + 7) * 1000}   | ${'35:03:07'}
      ${240 * 60 * 60 * 1000}                 | ${'240:00:00'}
      ${1000 * 60 * 60 * 1000}                | ${'1000:00:00'}
    `(`formats $milliseconds ms as $expected`, ({ milliseconds, expected }) => {
      expect(utils.formatTime(milliseconds)).toBe(expected);
    });

    it.each`
      milliseconds                           | expected
      ${-1}                                  | ${'00:00:00'}
      ${-499}                                | ${'00:00:00'}
      ${-1000}                               | ${'-00:00:01'}
      ${-60 * 1000}                          | ${'-00:01:00'}
      ${-(35 * 60 * 60 + 3 * 60 + 7) * 1000} | ${'-35:03:07'}
    `(`when negative, formats $milliseconds ms as $expected`, ({ milliseconds, expected }) => {
      expect(utils.formatTime(milliseconds)).toBe(expected);
    });
  });

  describe('toISODateFormat', () => {
    it('should format a Date object into yyyy-mm-dd format', () => {
      expect(utils.toISODateFormat(new Date('2020-01-29:00:00'))).toEqual('2020-01-29');
    });
  });

  describe('prettyTime methods', () => {
    // eslint-disable-next-line max-params
    const assertTimeUnits = (obj, minutes, hours, days, weeks) => {
      expect(obj.minutes).toBe(minutes);
      expect(obj.hours).toBe(hours);
      expect(obj.days).toBe(days);
      expect(obj.weeks).toBe(weeks);
    };

    describe('parseSeconds', () => {
      it('should correctly parse a negative value', () => {
        const zeroSeconds = utils.parseSeconds(-1000);

        assertTimeUnits(zeroSeconds, 16, 0, 0, 0);
      });

      it('should correctly parse a zero value', () => {
        const zeroSeconds = utils.parseSeconds(0);

        assertTimeUnits(zeroSeconds, 0, 0, 0, 0);
      });

      it('should correctly parse a small non-zero second values', () => {
        const subOneMinute = utils.parseSeconds(10);
        const aboveOneMinute = utils.parseSeconds(100);
        const manyMinutes = utils.parseSeconds(1000);

        assertTimeUnits(subOneMinute, 0, 0, 0, 0);
        assertTimeUnits(aboveOneMinute, 1, 0, 0, 0);
        assertTimeUnits(manyMinutes, 16, 0, 0, 0);
      });

      it('should correctly parse large second values', () => {
        const aboveOneHour = utils.parseSeconds(4800);
        const aboveOneDay = utils.parseSeconds(110000);
        const aboveOneWeek = utils.parseSeconds(25000000);

        assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
        assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
        assertTimeUnits(aboveOneWeek, 26, 0, 3, 173);
      });

      it('should correctly accept a custom param for hoursPerDay', () => {
        const config = { hoursPerDay: 24 };

        const aboveOneHour = utils.parseSeconds(4800, config);
        const aboveOneDay = utils.parseSeconds(110000, config);
        const aboveOneWeek = utils.parseSeconds(25000000, config);

        assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
        assertTimeUnits(aboveOneDay, 33, 6, 1, 0);
        assertTimeUnits(aboveOneWeek, 26, 8, 4, 57);
      });

      it('should correctly accept a custom param for daysPerWeek', () => {
        const config = { daysPerWeek: 7 };

        const aboveOneHour = utils.parseSeconds(4800, config);
        const aboveOneDay = utils.parseSeconds(110000, config);
        const aboveOneWeek = utils.parseSeconds(25000000, config);

        assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
        assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
        assertTimeUnits(aboveOneWeek, 26, 0, 0, 124);
      });

      it('should correctly accept custom params for daysPerWeek and hoursPerDay', () => {
        const config = { daysPerWeek: 55, hoursPerDay: 14 };

        const aboveOneHour = utils.parseSeconds(4800, config);
        const aboveOneDay = utils.parseSeconds(110000, config);
        const aboveOneWeek = utils.parseSeconds(25000000, config);

        assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
        assertTimeUnits(aboveOneDay, 33, 2, 2, 0);
        assertTimeUnits(aboveOneWeek, 26, 0, 1, 9);
      });

      it('should correctly parse values when limitedToHours is true', () => {
        const twoDays = utils.parseSeconds(173000, { limitToHours: true });

        assertTimeUnits(twoDays, 3, 48, 0, 0);
      });

      it('should correctly parse values when limitedToDays is true', () => {
        const sevenDays = utils.parseSeconds(648750, {
          hoursPerDay: 24,
          daysPerWeek: 7,
          limitToDays: true,
        });

        assertTimeUnits(sevenDays, 12, 12, 7, 0);
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

        const timeString = utils.stringifyTime(timeObject);

        expect(timeString).toBe('1w 4d 7h 20m');
      });

      it('should stringify values with some non-zero units', () => {
        const timeObject = {
          weeks: 0,
          days: 4,
          hours: 0,
          minutes: 20,
        };

        const timeString = utils.stringifyTime(timeObject);

        expect(timeString).toBe('4d 20m');
      });

      it('should stringify values with no non-zero units', () => {
        const timeObject = {
          weeks: 0,
          days: 0,
          hours: 0,
          minutes: 0,
        };

        const timeString = utils.stringifyTime(timeObject);

        expect(timeString).toBe('0m');
      });

      it('should return non-condensed representation of time object', () => {
        const timeObject = { weeks: 1, days: 0, hours: 1, minutes: 0 };

        expect(utils.stringifyTime(timeObject, true)).toEqual('1 week 1 hour');
      });
    });
  });

  describe('formatIso8601Date', () => {
    it('creates a ISO-8601 formated date', () => {
      expect(utils.formatIso8601Date(2021, 5, 1)).toBe('2021-06-01');
    });
  });
});
