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
