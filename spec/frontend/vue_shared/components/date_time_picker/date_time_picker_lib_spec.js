import timezoneMock from 'timezone-mock';

import {
  isValidInputString,
  inputStringToIsoDate,
  isoDateToInputString,
} from '~/vue_shared/components/date_time_picker/date_time_picker_lib';

describe('date time picker lib', () => {
  describe('isValidInputString', () => {
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
      it(`isValidInputString return ${output} for ${input}`, () => {
        expect(isValidInputString(input)).toBe(output);
      });
    });
  });

  describe('inputStringToIsoDate', () => {
    [
      '',
      'null',
      undefined,
      'abc',
      'xxxx-xx-xx',
      '9999-99-19',
      '2019-19-23',
      '2019-09-23 x',
      '2019-09-29 24:24:24',
    ].forEach(input => {
      it(`throws error for invalid input like ${input}`, () => {
        expect(() => inputStringToIsoDate(input)).toThrow();
      });
    });

    [
      {
        input: '2019-09-08 01:01:01',
        output: '2019-09-08T01:01:01Z',
      },
      {
        input: '2019-09-08 00:00:00',
        output: '2019-09-08T00:00:00Z',
      },
      {
        input: '2019-09-08 23:59:59',
        output: '2019-09-08T23:59:59Z',
      },
      {
        input: '2019-09-08',
        output: '2019-09-08T00:00:00Z',
      },
      {
        input: '2019-09-08',
        output: '2019-09-08T00:00:00Z',
      },
      {
        input: '2019-09-08 00:00:00',
        output: '2019-09-08T00:00:00Z',
      },
      {
        input: '2019-09-08 23:24:24',
        output: '2019-09-08T23:24:24Z',
      },
      {
        input: '2019-09-08 0:0:0',
        output: '2019-09-08T00:00:00Z',
      },
    ].forEach(({ input, output }) => {
      it(`returns ${output} from ${input}`, () => {
        expect(inputStringToIsoDate(input)).toBe(output);
      });
    });

    describe('timezone formatting', () => {
      const value = '2019-09-08 01:01:01';
      const utcResult = '2019-09-08T01:01:01Z';
      const localResult = '2019-09-08T08:01:01Z';

      test.each`
        val      | locatTimezone   | utc          | result
        ${value} | ${'UTC'}        | ${undefined} | ${utcResult}
        ${value} | ${'UTC'}        | ${false}     | ${utcResult}
        ${value} | ${'UTC'}        | ${true}      | ${utcResult}
        ${value} | ${'US/Pacific'} | ${undefined} | ${localResult}
        ${value} | ${'US/Pacific'} | ${false}     | ${localResult}
        ${value} | ${'US/Pacific'} | ${true}      | ${utcResult}
      `(
        'when timezone is $locatTimezone, formats $result for utc = $utc',
        ({ val, locatTimezone, utc, result }) => {
          timezoneMock.register(locatTimezone);

          expect(inputStringToIsoDate(val, utc)).toBe(result);

          timezoneMock.unregister();
        },
      );
    });
  });

  describe('isoDateToInputString', () => {
    [
      {
        input: '2019-09-08T01:01:01Z',
        output: '2019-09-08 01:01:01',
      },
      {
        input: '2019-09-08T01:01:01.999Z',
        output: '2019-09-08 01:01:01',
      },
      {
        input: '2019-09-08T00:00:00Z',
        output: '2019-09-08 00:00:00',
      },
    ].forEach(({ input, output }) => {
      it(`returns ${output} for ${input}`, () => {
        expect(isoDateToInputString(input)).toBe(output);
      });
    });

    describe('timezone formatting', () => {
      const value = '2019-09-08T08:01:01Z';
      const utcResult = '2019-09-08 08:01:01';
      const localResult = '2019-09-08 01:01:01';

      test.each`
        val      | locatTimezone   | utc          | result
        ${value} | ${'UTC'}        | ${undefined} | ${utcResult}
        ${value} | ${'UTC'}        | ${false}     | ${utcResult}
        ${value} | ${'UTC'}        | ${true}      | ${utcResult}
        ${value} | ${'US/Pacific'} | ${undefined} | ${localResult}
        ${value} | ${'US/Pacific'} | ${false}     | ${localResult}
        ${value} | ${'US/Pacific'} | ${true}      | ${utcResult}
      `(
        'when timezone is $locatTimezone, formats $result for utc = $utc',
        ({ val, locatTimezone, utc, result }) => {
          timezoneMock.register(locatTimezone);

          expect(isoDateToInputString(val, utc)).toBe(result);

          timezoneMock.unregister();
        },
      );
    });
  });
});
