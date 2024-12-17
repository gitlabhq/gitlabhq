import {
  bytesToKiB,
  bytesToMiB,
  bytesToGiB,
  numberToHumanSizeSplit,
  numberToHumanSize,
  numberToMetricPrefix,
  sum,
  isOdd,
  median,
  changeInPercent,
  formattedChangeInPercent,
  isNumeric,
  isPositiveInteger,
  splitDecimalNumber,
  countFloatingPointDigits,
} from '~/lib/utils/number_utils';

describe('Number Utils', () => {
  describe('bytesToKiB', () => {
    it('calculates KiB for the given bytes', () => {
      expect(bytesToKiB(1024)).toEqual(1);
      expect(bytesToKiB(1000)).toEqual(0.9765625);
    });
  });

  describe('bytesToMiB', () => {
    it('calculates MiB for the given bytes', () => {
      expect(bytesToMiB(1048576)).toEqual(1);
      expect(bytesToMiB(1000000)).toEqual(0.95367431640625);
    });
  });

  describe('bytesToGiB', () => {
    it('calculates GiB for the given bytes', () => {
      expect(bytesToGiB(1073741824)).toEqual(1);
      expect(bytesToGiB(10737418240)).toEqual(10);
    });
  });

  describe('numberToHumanSizeSplit', () => {
    it('should return bytes', () => {
      expect(numberToHumanSizeSplit({ size: 654 })).toEqual(['654', 'B']);
      expect(numberToHumanSizeSplit({ size: -654 })).toEqual(['-654', 'B']);
    });

    it('should return KiB', () => {
      expect(numberToHumanSizeSplit({ size: 1079 })).toEqual(['1.05', 'KiB']);
      expect(numberToHumanSizeSplit({ size: -1079 })).toEqual(['-1.05', 'KiB']);
    });

    it('should return MiB', () => {
      expect(numberToHumanSizeSplit({ size: 10485764 })).toEqual(['10.00', 'MiB']);
      expect(numberToHumanSizeSplit({ size: -10485764 })).toEqual(['-10.00', 'MiB']);
    });

    it('should return GiB', () => {
      expect(numberToHumanSizeSplit({ size: 10737418240 })).toEqual(['10.00', 'GiB']);
      expect(numberToHumanSizeSplit({ size: -10737418240 })).toEqual(['-10.00', 'GiB']);
    });

    it('should localize the delimiter', () => {
      expect(numberToHumanSizeSplit({ size: 10737418240, locale: 'fr' })).toEqual(['10,00', 'GiB']);
      expect(numberToHumanSizeSplit({ size: 10737418240 * 1000, locale: 'it' })).toEqual([
        '10.000,00',
        'GiB',
      ]);
    });
  });

  describe('numberToHumanSize', () => {
    it('should return bytes', () => {
      expect(numberToHumanSize(654)).toEqual('654 B');
      expect(numberToHumanSize(-654)).toEqual('-654 B');
    });

    it('should return KiB', () => {
      expect(numberToHumanSize(1079)).toEqual('1.05 KiB');
      expect(numberToHumanSize(-1079)).toEqual('-1.05 KiB');
    });

    it('should return MiB', () => {
      expect(numberToHumanSize(10485764)).toEqual('10.00 MiB');
      expect(numberToHumanSize(-10485764)).toEqual('-10.00 MiB');
    });

    it('should return GiB', () => {
      expect(numberToHumanSize(10737418240)).toEqual('10.00 GiB');
      expect(numberToHumanSize(-10737418240)).toEqual('-10.00 GiB');
    });
  });

  describe('numberToMetricPrefix', () => {
    it.each`
      number       | expected
      ${123}       | ${'123'}
      ${1000}      | ${'1k'}
      ${1234}      | ${'1.2k'}
      ${12345}     | ${'12.3k'}
      ${123456}    | ${'123.5k'}
      ${1000000}   | ${'1m'}
      ${1234567}   | ${'1.2m'}
      ${12345678}  | ${'12.3m'}
      ${123456789} | ${'123.5m'}
    `('returns $expected given $number', ({ number, expected }) => {
      expect(numberToMetricPrefix(number)).toBe(expected);
      expect(numberToMetricPrefix(number, true)).toBe(expected.toUpperCase());
    });
  });

  describe('sum', () => {
    it('should add up two values', () => {
      expect(sum(1, 2)).toEqual(3);
    });

    it('should add up all the values in an array when passed to a reducer', () => {
      expect([1, 2, 3, 4, 5].reduce(sum)).toEqual(15);
    });
  });

  describe('isOdd', () => {
    it('should return 0 with a even number', () => {
      expect(isOdd(2)).toEqual(0);
    });

    it('should return 1 with a odd number', () => {
      expect(isOdd(1)).toEqual(1);
    });
  });

  describe('median', () => {
    it('computes the median for a given array with odd length', () => {
      const items = [10, 27, 20, 5, 19];
      expect(median(items)).toBe(19);
    });

    it('computes the median for a given array with even length', () => {
      const items = [10, 27, 20, 5, 19, 4];
      expect(median(items)).toBe(14.5);
    });
  });

  describe('changeInPercent', () => {
    it.each`
      firstValue | secondValue | expectedOutput
      ${99}      | ${100}      | ${1}
      ${100}     | ${99}       | ${-1}
      ${0}       | ${99}       | ${Infinity}
      ${2}       | ${2}        | ${0}
      ${-100}    | ${-99}      | ${1}
    `(
      'computes the change between $firstValue and $secondValue in percent',
      ({ firstValue, secondValue, expectedOutput }) => {
        expect(changeInPercent(firstValue, secondValue)).toBe(expectedOutput);
      },
    );
  });

  describe('formattedChangeInPercent', () => {
    it('prepends "%" to the output', () => {
      expect(formattedChangeInPercent(1, 2)).toMatch(/%$/);
    });

    it('indicates if the change was a decrease', () => {
      expect(formattedChangeInPercent(100, 99)).toContain('-1');
    });

    it('indicates if the change was an increase', () => {
      expect(formattedChangeInPercent(99, 100)).toContain('+1');
    });

    it('shows "-" per default if the change can not be expressed in an integer', () => {
      expect(formattedChangeInPercent(0, 1)).toBe('-');
    });

    it('shows the given fallback if the change can not be expressed in an integer', () => {
      expect(formattedChangeInPercent(0, 1, { nonFiniteResult: '*' })).toBe('*');
    });
  });

  describe('isNumeric', () => {
    it.each`
      value        | outcome
      ${0}         | ${true}
      ${12345}     | ${true}
      ${'0'}       | ${true}
      ${'12345'}   | ${true}
      ${1.0}       | ${true}
      ${'1.0'}     | ${true}
      ${'abcd'}    | ${false}
      ${'abcd100'} | ${false}
      ${''}        | ${false}
      ${false}     | ${false}
      ${true}      | ${false}
      ${undefined} | ${false}
      ${null}      | ${false}
    `('when called with $value it returns $outcome', ({ value, outcome }) => {
      expect(isNumeric(value)).toBe(outcome);
    });
  });

  describe.each`
    value        | outcome
    ${0}         | ${true}
    ${'0'}       | ${true}
    ${12345}     | ${true}
    ${'12345'}   | ${true}
    ${-1}        | ${false}
    ${'-1'}      | ${false}
    ${1.01}      | ${false}
    ${'1.01'}    | ${false}
    ${'abcd'}    | ${false}
    ${'100abcd'} | ${false}
    ${'abcd100'} | ${false}
    ${''}        | ${false}
    ${false}     | ${false}
    ${true}      | ${false}
    ${undefined} | ${false}
    ${null}      | ${false}
    ${Infinity}  | ${false}
  `('isPositiveInteger', ({ value, outcome }) => {
    it(`when called with ${typeof value} ${value} it returns ${outcome}`, () => {
      expect(isPositiveInteger(value)).toBe(outcome);
    });
  });

  describe('splitDecimalNumber', () => {
    it.each`
      value          | integer   | decimal
      ${null}        | ${null}   | ${null}
      ${0}           | ${'0'}    | ${'0'}
      ${'1.0'}       | ${'1'}    | ${'0'}
      ${'1024.1293'} | ${'1024'} | ${'1293'}
    `(
      'when called with $value it returns integer=$integer and decimal=$decimal',
      ({ value, integer, decimal }) => {
        expect(splitDecimalNumber(value)).toEqual({ integer, decimal });
      },
    );
  });

  describe('countFloatingPointDigits', () => {
    it.each`
      value          | digits
      ${null}        | ${0}
      ${0}           | ${0}
      ${'1.0'}       | ${1}
      ${'5.3'}       | ${1}
      ${'3.20'}      | ${2}
      ${'3.04'}      | ${2}
      ${'14.123'}    | ${3}
      ${'1024.1293'} | ${4}
    `('when called with $value it returns $digits', ({ value, digits }) => {
      expect(countFloatingPointDigits(value)).toBe(digits);
    });
  });
});
