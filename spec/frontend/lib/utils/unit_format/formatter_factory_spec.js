import {
  numberFormatter,
  suffixFormatter,
  scaledSIFormatter,
} from '~/lib/utils/unit_format/formatter_factory';

describe('unit_format/formatter_factory', () => {
  describe('numberFormatter', () => {
    let formatNumber;
    beforeEach(() => {
      formatNumber = numberFormatter();
    });

    it('formats a integer', () => {
      expect(formatNumber(1)).toEqual('1');
      expect(formatNumber(100)).toEqual('100');
      expect(formatNumber(1000)).toEqual('1,000');
      expect(formatNumber(10000)).toEqual('10,000');
      expect(formatNumber(1000000)).toEqual('1,000,000');
    });

    it('formats a floating point number', () => {
      expect(formatNumber(0.1)).toEqual('0.1');
      expect(formatNumber(0.1, 0)).toEqual('0');
      expect(formatNumber(0.1, 2)).toEqual('0.10');
      expect(formatNumber(0.1, 3)).toEqual('0.100');

      expect(formatNumber(12.345)).toEqual('12.345');
      expect(formatNumber(12.345, 2)).toEqual('12.35');
      expect(formatNumber(12.345, 4)).toEqual('12.3450');
    });

    it('formats a large integer with a length limit', () => {
      expect(formatNumber(10 ** 7, undefined)).toEqual('10,000,000');
      expect(formatNumber(10 ** 7, undefined, 9)).toEqual('1.00e+7');
      expect(formatNumber(10 ** 7, undefined, 10)).toEqual('10,000,000');
    });
  });

  describe('suffixFormatter', () => {
    let formatSuffix;
    beforeEach(() => {
      formatSuffix = suffixFormatter('pop.', undefined);
    });

    it('formats a integer', () => {
      expect(formatSuffix(1)).toEqual('1pop.');
      expect(formatSuffix(100)).toEqual('100pop.');
      expect(formatSuffix(1000)).toEqual('1,000pop.');
      expect(formatSuffix(10000)).toEqual('10,000pop.');
      expect(formatSuffix(1000000)).toEqual('1,000,000pop.');
    });

    it('formats a floating point number', () => {
      expect(formatSuffix(0.1)).toEqual('0.1pop.');
      expect(formatSuffix(0.1, 0)).toEqual('0pop.');
      expect(formatSuffix(0.1, 2)).toEqual('0.10pop.');
      expect(formatSuffix(0.1, 3)).toEqual('0.100pop.');

      expect(formatSuffix(12.345)).toEqual('12.345pop.');
      expect(formatSuffix(12.345, 2)).toEqual('12.35pop.');
      expect(formatSuffix(12.345, 4)).toEqual('12.3450pop.');
    });

    it('formats a negative integer', () => {
      expect(formatSuffix(-1)).toEqual('-1pop.');
      expect(formatSuffix(-100)).toEqual('-100pop.');
      expect(formatSuffix(-1000)).toEqual('-1,000pop.');
      expect(formatSuffix(-10000)).toEqual('-10,000pop.');
      expect(formatSuffix(-1000000)).toEqual('-1,000,000pop.');
    });

    it('formats a floating point nugative number', () => {
      expect(formatSuffix(-0.1)).toEqual('-0.1pop.');
      expect(formatSuffix(-0.1, 0)).toEqual('-0pop.');
      expect(formatSuffix(-0.1, 2)).toEqual('-0.10pop.');
      expect(formatSuffix(-0.1, 3)).toEqual('-0.100pop.');

      expect(formatSuffix(-12.345)).toEqual('-12.345pop.');
      expect(formatSuffix(-12.345, 2)).toEqual('-12.35pop.');
      expect(formatSuffix(-12.345, 4)).toEqual('-12.3450pop.');
    });

    it('formats a large integer', () => {
      expect(formatSuffix(10 ** 7)).toEqual('10,000,000pop.');
      expect(formatSuffix(10 ** 10)).toEqual('10,000,000,000pop.');
    });

    it('formats a large integer with a length limit', () => {
      expect(formatSuffix(10 ** 7, undefined, 10)).toEqual('1.00e+7pop.');
      expect(formatSuffix(10 ** 10, undefined, 10)).toEqual('1.00e+10pop.');
    });
  });

  describe('scaledSIFormatter', () => {
    describe('scaled format', () => {
      let formatScaled;

      beforeEach(() => {
        formatScaled = scaledSIFormatter('B');
      });

      it('formats bytes', () => {
        expect(formatScaled(12.345)).toEqual('12.345B');
        expect(formatScaled(12.345, 0)).toEqual('12B');
        expect(formatScaled(12.345, 1)).toEqual('12.3B');
        expect(formatScaled(12.345, 2)).toEqual('12.35B');
      });

      it('formats bytes in a scale', () => {
        expect(formatScaled(1)).toEqual('1B');
        expect(formatScaled(10)).toEqual('10B');
        expect(formatScaled(10 ** 2)).toEqual('100B');
        expect(formatScaled(10 ** 3)).toEqual('1kB');
        expect(formatScaled(10 ** 4)).toEqual('10kB');
        expect(formatScaled(10 ** 5)).toEqual('100kB');
        expect(formatScaled(10 ** 6)).toEqual('1MB');
        expect(formatScaled(10 ** 7)).toEqual('10MB');
        expect(formatScaled(10 ** 8)).toEqual('100MB');
        expect(formatScaled(10 ** 9)).toEqual('1GB');
        expect(formatScaled(10 ** 10)).toEqual('10GB');
        expect(formatScaled(10 ** 11)).toEqual('100GB');
      });
    });

    describe('scaled format with offset', () => {
      let formatScaled;

      beforeEach(() => {
        // formats gigabytes
        formatScaled = scaledSIFormatter('B', 3);
      });

      it('formats floating point numbers', () => {
        expect(formatScaled(12.345)).toEqual('12.345GB');
        expect(formatScaled(12.345, 0)).toEqual('12GB');
        expect(formatScaled(12.345, 1)).toEqual('12.3GB');
        expect(formatScaled(12.345, 2)).toEqual('12.35GB');
      });

      it('formats large numbers scaled', () => {
        expect(formatScaled(1)).toEqual('1GB');
        expect(formatScaled(1, 1)).toEqual('1.0GB');
        expect(formatScaled(10)).toEqual('10GB');
        expect(formatScaled(10 ** 2)).toEqual('100GB');
        expect(formatScaled(10 ** 3)).toEqual('1TB');
        expect(formatScaled(10 ** 4)).toEqual('10TB');
        expect(formatScaled(10 ** 5)).toEqual('100TB');
        expect(formatScaled(10 ** 6)).toEqual('1PB');
        expect(formatScaled(10 ** 7)).toEqual('10PB');
        expect(formatScaled(10 ** 8)).toEqual('100PB');
        expect(formatScaled(10 ** 9)).toEqual('1EB');
      });

      it('formatting of too large numbers is not suported', () => {
        // formatting YB is out of range
        expect(() => scaledSIFormatter('B', 9)).toThrow();
      });
    });

    describe('scaled format with negative offset', () => {
      let formatScaled;

      beforeEach(() => {
        formatScaled = scaledSIFormatter('g', -1);
      });

      it('formats floating point numbers', () => {
        expect(formatScaled(12.345)).toEqual('12.345mg');
        expect(formatScaled(12.345, 0)).toEqual('12mg');
        expect(formatScaled(12.345, 1)).toEqual('12.3mg');
        expect(formatScaled(12.345, 2)).toEqual('12.35mg');
      });

      it('formats large numbers scaled', () => {
        expect(formatScaled(1)).toEqual('1mg');
        expect(formatScaled(1, 1)).toEqual('1.0mg');
        expect(formatScaled(10)).toEqual('10mg');
        expect(formatScaled(10 ** 2)).toEqual('100mg');
        expect(formatScaled(10 ** 3)).toEqual('1g');
        expect(formatScaled(10 ** 4)).toEqual('10g');
        expect(formatScaled(10 ** 5)).toEqual('100g');
        expect(formatScaled(10 ** 6)).toEqual('1kg');
        expect(formatScaled(10 ** 7)).toEqual('10kg');
        expect(formatScaled(10 ** 8)).toEqual('100kg');
      });

      it('formats negative numbers scaled', () => {
        expect(formatScaled(-12.345)).toEqual('-12.345mg');
        expect(formatScaled(-12.345, 0)).toEqual('-12mg');
        expect(formatScaled(-12.345, 1)).toEqual('-12.3mg');
        expect(formatScaled(-12.345, 2)).toEqual('-12.35mg');

        expect(formatScaled(-10)).toEqual('-10mg');
        expect(formatScaled(-100)).toEqual('-100mg');
        expect(formatScaled(-(10 ** 4))).toEqual('-10g');
      });
    });
  });
});
