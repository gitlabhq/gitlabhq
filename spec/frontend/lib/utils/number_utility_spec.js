import {
  formatRelevantDigits,
  bytesToKiB,
  bytesToMiB,
  bytesToGiB,
  numberToHumanSize,
  sum,
  isOdd,
  median,
  changeInPercent,
  formattedChangeInPercent,
} from '~/lib/utils/number_utils';

describe('Number Utils', () => {
  describe('formatRelevantDigits', () => {
    it('returns an empty string when the number is NaN', () => {
      expect(formatRelevantDigits('fail')).toBe('');
    });

    it('returns 4 decimals when there is 4 plus digits to the left', () => {
      const formattedNumber = formatRelevantDigits('1000.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];

      expect(rightFromDecimal.length).toBe(4);
      expect(leftFromDecimal.length).toBe(4);
    });

    it('returns 3 decimals when there is 1 digit to the left', () => {
      const formattedNumber = formatRelevantDigits('0.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];

      expect(rightFromDecimal.length).toBe(3);
      expect(leftFromDecimal.length).toBe(1);
    });

    it('returns 2 decimals when there is 2 digits to the left', () => {
      const formattedNumber = formatRelevantDigits('10.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];

      expect(rightFromDecimal.length).toBe(2);
      expect(leftFromDecimal.length).toBe(2);
    });

    it('returns 1 decimal when there is 3 digits to the left', () => {
      const formattedNumber = formatRelevantDigits('100.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];

      expect(rightFromDecimal.length).toBe(1);
      expect(leftFromDecimal.length).toBe(3);
    });
  });

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

  describe('numberToHumanSize', () => {
    it('should return bytes', () => {
      expect(numberToHumanSize(654)).toEqual('654 bytes');
    });

    it('should return KiB', () => {
      expect(numberToHumanSize(1079)).toEqual('1.05 KiB');
    });

    it('should return MiB', () => {
      expect(numberToHumanSize(10485764)).toEqual('10.00 MiB');
    });

    it('should return GiB', () => {
      expect(numberToHumanSize(10737418240)).toEqual('10.00 GiB');
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
});
