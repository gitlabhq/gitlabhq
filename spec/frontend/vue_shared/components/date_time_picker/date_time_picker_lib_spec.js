import * as dateTimePickerLib from '~/vue_shared/components/date_time_picker/date_time_picker_lib';

describe('date time picker lib', () => {
  describe('isValidDate', () => {
    [
      {
        input: '2019-09-09T00:00:00.000Z',
        output: true,
      },
      {
        input: '2019-09-09T000:00.000Z',
        output: false,
      },
      {
        input: 'a2019-09-09T000:00.000Z',
        output: false,
      },
      {
        input: '2019-09-09T',
        output: false,
      },
      {
        input: '2019-09-09',
        output: true,
      },
      {
        input: '2019-9-9',
        output: true,
      },
      {
        input: '2019-9-',
        output: true,
      },
      {
        input: '2019--',
        output: false,
      },
      {
        input: '2019',
        output: true,
      },
      {
        input: '',
        output: false,
      },
      {
        input: null,
        output: false,
      },
    ].forEach(({ input, output }) => {
      it(`isValidDate return ${output} for ${input}`, () => {
        expect(dateTimePickerLib.isValidDate(input)).toBe(output);
      });
    });
  });

  describe('getTimeWindow', () => {
    [
      {
        args: [
          {
            start: '2019-10-01T18:27:47.000Z',
            end: '2019-10-01T21:27:47.000Z',
          },
          dateTimePickerLib.defaultTimeWindows,
        ],
        expected: 'threeHours',
      },
      {
        args: [
          {
            start: '2019-10-01T28:27:47.000Z',
            end: '2019-10-01T21:27:47.000Z',
          },
          dateTimePickerLib.defaultTimeWindows,
        ],
        expected: null,
      },
      {
        args: [
          {
            start: '',
            end: '',
          },
          dateTimePickerLib.defaultTimeWindows,
        ],
        expected: null,
      },
      {
        args: [
          {
            start: null,
            end: null,
          },
          dateTimePickerLib.defaultTimeWindows,
        ],
        expected: null,
      },
      {
        args: [{}, dateTimePickerLib.defaultTimeWindows],
        expected: null,
      },
    ].forEach(({ args, expected }) => {
      it(`returns "${expected}" with args=${JSON.stringify(args)}`, () => {
        expect(dateTimePickerLib.getTimeWindowKey(...args)).toEqual(expected);
      });
    });
  });

  describe('getTimeRange', () => {
    function secondsBetween({ start, end }) {
      return (new Date(end) - new Date(start)) / 1000;
    }

    function minutesBetween(timeRange) {
      return secondsBetween(timeRange) / 60;
    }

    function hoursBetween(timeRange) {
      return minutesBetween(timeRange) / 60;
    }

    it('defaults to an 8 hour (28800s) difference', () => {
      const params = dateTimePickerLib.getTimeRange();

      expect(hoursBetween(params)).toEqual(8);
    });

    it('accepts time window as an argument', () => {
      const params = dateTimePickerLib.getTimeRange('thirtyMinutes');

      expect(minutesBetween(params)).toEqual(30);
    });

    it('returns a value for every defined time window', () => {
      const nonDefaultWindows = Object.entries(dateTimePickerLib.defaultTimeWindows).filter(
        ([, timeWindow]) => !timeWindow.default,
      );
      nonDefaultWindows.forEach(timeWindow => {
        const params = dateTimePickerLib.getTimeRange(timeWindow[0]);

        // Ensure we're not returning the default
        expect(hoursBetween(params)).not.toEqual(8);
      });
    });
  });

  describe('stringToISODate', () => {
    ['', 'null', undefined, 'abc'].forEach(input => {
      it(`throws error for invalid input like ${input}`, done => {
        try {
          dateTimePickerLib.stringToISODate(input);
        } catch (e) {
          expect(e).toBeDefined();
          done();
        }
      });
    });
    [
      {
        input: '2019-09-09 01:01:01',
        output: '2019-09-09T01:01:01Z',
      },
      {
        input: '2019-09-09 00:00:00',
        output: '2019-09-09T00:00:00Z',
      },
      {
        input: '2019-09-09 23:59:59',
        output: '2019-09-09T23:59:59Z',
      },
      {
        input: '2019-09-09',
        output: '2019-09-09T00:00:00Z',
      },
    ].forEach(({ input, output }) => {
      it(`returns ${output} from ${input}`, () => {
        expect(dateTimePickerLib.stringToISODate(input)).toBe(output);
      });
    });
  });

  describe('truncateZerosInDateTime', () => {
    [
      {
        input: '',
        output: '',
      },
      {
        input: '2019-10-10',
        output: '2019-10-10',
      },
      {
        input: '2019-10-10 00:00:01',
        output: '2019-10-10 00:00:01',
      },
      {
        input: '2019-10-10 00:00:00',
        output: '2019-10-10',
      },
    ].forEach(({ input, output }) => {
      it(`truncateZerosInDateTime return ${output} for ${input}`, () => {
        expect(dateTimePickerLib.truncateZerosInDateTime(input)).toBe(output);
      });
    });
  });

  describe('isDateTimePickerInputValid', () => {
    [
      {
        input: null,
        output: false,
      },
      {
        input: '',
        output: false,
      },
      {
        input: 'xxxx-xx-xx',
        output: false,
      },
      {
        input: '9999-99-19',
        output: false,
      },
      {
        input: '2019-19-23',
        output: false,
      },
      {
        input: '2019-09-23',
        output: true,
      },
      {
        input: '2019-09-23 x',
        output: false,
      },
      {
        input: '2019-09-29 0:0:0',
        output: false,
      },
      {
        input: '2019-09-29 00:00:00',
        output: true,
      },
      {
        input: '2019-09-29 24:24:24',
        output: false,
      },
      {
        input: '2019-09-29 23:24:24',
        output: true,
      },
      {
        input: '2019-09-29 23:24:24 ',
        output: false,
      },
    ].forEach(({ input, output }) => {
      it(`returns ${output} for ${input}`, () => {
        expect(dateTimePickerLib.isDateTimePickerInputValid(input)).toBe(output);
      });
    });
  });
});
