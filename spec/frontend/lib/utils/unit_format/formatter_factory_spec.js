import {
  numberFormatter,
  suffixFormatter,
  scaledSIFormatter,
  scaledBinaryFormatter,
} from '~/lib/utils/unit_format/formatter_factory';

describe('unit_format/formatter_factory', () => {
  describe('numberFormatter', () => {
    let formatNumber;
    beforeEach(() => {
      formatNumber = numberFormatter();
    });

    it('formats a integer', () => {
      expect(formatNumber(1)).toBe('1');
      expect(formatNumber(100)).toBe('100');
      expect(formatNumber(1000)).toBe('1,000');
      expect(formatNumber(10000)).toBe('10,000');
      expect(formatNumber(1000000)).toBe('1,000,000');
    });

    it('formats a floating point number', () => {
      expect(formatNumber(0.1)).toBe('0.1');
      expect(formatNumber(0.1, 0)).toBe('0');
      expect(formatNumber(0.1, 2)).toBe('0.10');
      expect(formatNumber(0.1, 3)).toBe('0.100');

      expect(formatNumber(12.345)).toBe('12.345');
      expect(formatNumber(12.345, 2)).toBe('12.35');
      expect(formatNumber(12.345, 4)).toBe('12.3450');
    });

    it('formats a large integer with a max length - using legacy positional argument', () => {
      expect(formatNumber(10 ** 7, undefined)).toBe('10,000,000');
      expect(formatNumber(10 ** 7, undefined, 9)).toBe('1.00e+7');
      expect(formatNumber(10 ** 7, undefined, 10)).toBe('10,000,000');
    });

    it('formats a large integer with a max length', () => {
      expect(formatNumber(10 ** 7, undefined, { maxLength: 9 })).toBe('1.00e+7');
      expect(formatNumber(10 ** 7, undefined, { maxLength: 10 })).toBe('10,000,000');
    });

    describe('formats with a different locale', () => {
      let originalLang;

      beforeAll(() => {
        originalLang = document.documentElement.lang;
        document.documentElement.lang = 'es';
      });

      afterAll(() => {
        document.documentElement.lang = originalLang;
      });

      it('formats a using the correct thousands separator', () => {
        expect(formatNumber(1000000)).toBe('1.000.000');
      });

      it('formats a using the correct decimal separator', () => {
        expect(formatNumber(12.345)).toBe('12,345');
      });
    });
  });

  describe('suffixFormatter', () => {
    let formatSuffix;
    beforeEach(() => {
      formatSuffix = suffixFormatter('pop.', undefined);
    });

    it('formats a integer', () => {
      expect(formatSuffix(1)).toBe('1pop.');
      expect(formatSuffix(100)).toBe('100pop.');
      expect(formatSuffix(1000)).toBe('1,000pop.');
      expect(formatSuffix(10000)).toBe('10,000pop.');
      expect(formatSuffix(1000000)).toBe('1,000,000pop.');
    });

    it('formats a floating point number', () => {
      expect(formatSuffix(0.1)).toBe('0.1pop.');
      expect(formatSuffix(0.1, 0)).toBe('0pop.');
      expect(formatSuffix(0.1, 2)).toBe('0.10pop.');
      expect(formatSuffix(0.1, 3)).toBe('0.100pop.');

      expect(formatSuffix(12.345)).toBe('12.345pop.');
      expect(formatSuffix(12.345, 2)).toBe('12.35pop.');
      expect(formatSuffix(12.345, 4)).toBe('12.3450pop.');
    });

    it('formats a negative integer', () => {
      expect(formatSuffix(-1)).toBe('-1pop.');
      expect(formatSuffix(-100)).toBe('-100pop.');
      expect(formatSuffix(-1000)).toBe('-1,000pop.');
      expect(formatSuffix(-10000)).toBe('-10,000pop.');
      expect(formatSuffix(-1000000)).toBe('-1,000,000pop.');
    });

    it('formats a floating point negative number', () => {
      expect(formatSuffix(-0.1)).toBe('-0.1pop.');
      expect(formatSuffix(-0.1, 0)).toBe('-0pop.');
      expect(formatSuffix(-0.1, 2)).toBe('-0.10pop.');
      expect(formatSuffix(-0.1, 3)).toBe('-0.100pop.');

      expect(formatSuffix(-12.345)).toBe('-12.345pop.');
      expect(formatSuffix(-12.345, 2)).toBe('-12.35pop.');
      expect(formatSuffix(-12.345, 4)).toBe('-12.3450pop.');
    });

    it('formats a large integer', () => {
      expect(formatSuffix(10 ** 7)).toBe('10,000,000pop.');
      expect(formatSuffix(10 ** 10)).toBe('10,000,000,000pop.');
    });

    it('formats using a unit separator', () => {
      expect(formatSuffix(10, 0, { unitSeparator: ' ' })).toBe('10 pop.');
      expect(formatSuffix(10, 0, { unitSeparator: ' x ' })).toBe('10 x pop.');
    });

    it('formats a large integer with a max length - using legacy positional argument', () => {
      expect(formatSuffix(10 ** 7, undefined, 10)).toBe('1.00e+7pop.');
      expect(formatSuffix(10 ** 10, undefined, 10)).toBe('1.00e+10pop.');
    });

    it('formats a large integer with a max length', () => {
      expect(formatSuffix(10 ** 7, undefined, { maxLength: 10 })).toBe('1.00e+7pop.');
      expect(formatSuffix(10 ** 10, undefined, { maxLength: 10 })).toBe('1.00e+10pop.');
    });
  });

  describe('scaledSIFormatter', () => {
    describe('scaled format', () => {
      let formatGibibytes;

      beforeEach(() => {
        formatGibibytes = scaledSIFormatter('B');
      });

      it('formats bytes', () => {
        expect(formatGibibytes(12.345)).toBe('12.345B');
        expect(formatGibibytes(12.345, 0)).toBe('12B');
        expect(formatGibibytes(12.345, 1)).toBe('12.3B');
        expect(formatGibibytes(12.345, 2)).toBe('12.35B');
      });

      it('formats bytes in a decimal scale', () => {
        expect(formatGibibytes(1)).toBe('1B');
        expect(formatGibibytes(10)).toBe('10B');
        expect(formatGibibytes(10 ** 2)).toBe('100B');
        expect(formatGibibytes(10 ** 3)).toBe('1kB');
        expect(formatGibibytes(10 ** 4)).toBe('10kB');
        expect(formatGibibytes(10 ** 5)).toBe('100kB');
        expect(formatGibibytes(10 ** 6)).toBe('1MB');
        expect(formatGibibytes(10 ** 7)).toBe('10MB');
        expect(formatGibibytes(10 ** 8)).toBe('100MB');
        expect(formatGibibytes(10 ** 9)).toBe('1GB');
        expect(formatGibibytes(10 ** 10)).toBe('10GB');
        expect(formatGibibytes(10 ** 11)).toBe('100GB');
      });

      it('formats bytes using a unit separator', () => {
        expect(formatGibibytes(1, 0, { unitSeparator: ' ' })).toBe('1 B');
      });
    });

    describe('scaled format with offset', () => {
      let formatGigaBytes;

      beforeEach(() => {
        // formats gigabytes
        formatGigaBytes = scaledSIFormatter('B', 3);
      });

      it('formats floating point numbers', () => {
        expect(formatGigaBytes(12.345)).toBe('12.345GB');
        expect(formatGigaBytes(12.345, 0)).toBe('12GB');
        expect(formatGigaBytes(12.345, 1)).toBe('12.3GB');
        expect(formatGigaBytes(12.345, 2)).toBe('12.35GB');
      });

      it('formats large numbers scaled', () => {
        expect(formatGigaBytes(1)).toBe('1GB');
        expect(formatGigaBytes(1, 1)).toBe('1.0GB');
        expect(formatGigaBytes(10)).toBe('10GB');
        expect(formatGigaBytes(10 ** 2)).toBe('100GB');
        expect(formatGigaBytes(10 ** 3)).toBe('1TB');
        expect(formatGigaBytes(10 ** 4)).toBe('10TB');
        expect(formatGigaBytes(10 ** 5)).toBe('100TB');
        expect(formatGigaBytes(10 ** 6)).toBe('1PB');
        expect(formatGigaBytes(10 ** 7)).toBe('10PB');
        expect(formatGigaBytes(10 ** 8)).toBe('100PB');
        expect(formatGigaBytes(10 ** 9)).toBe('1EB');
      });

      it('formats bytes using a unit separator', () => {
        expect(formatGigaBytes(1, undefined, { unitSeparator: ' ' })).toBe('1 GB');
      });

      it('formats long byte numbers with max length - using legacy positional argument', () => {
        expect(formatGigaBytes(1, 8, 7)).toBe('1.00e+0GB');
      });

      it('formats long byte numbers with max length', () => {
        expect(formatGigaBytes(1, 8)).toBe('1.00000000GB');
        expect(formatGigaBytes(1, 8, { maxLength: 7 })).toBe('1.00e+0GB');
      });

      it('formatting of too large numbers is not suported', () => {
        // formatting YB is out of range
        expect(() => scaledSIFormatter('B', 9)).toThrow();
      });
    });

    describe('scaled format with negative offset', () => {
      let formatMilligrams;

      beforeEach(() => {
        formatMilligrams = scaledSIFormatter('g', -1);
      });

      it('formats floating point numbers', () => {
        expect(formatMilligrams(1.0)).toBe('1mg');
        expect(formatMilligrams(12.345)).toBe('12.345mg');
        expect(formatMilligrams(12.345, 0)).toBe('12mg');
        expect(formatMilligrams(12.345, 1)).toBe('12.3mg');
        expect(formatMilligrams(12.345, 2)).toBe('12.35mg');
      });

      it('formats large numbers scaled', () => {
        expect(formatMilligrams(10)).toBe('10mg');
        expect(formatMilligrams(10 ** 2)).toBe('100mg');
        expect(formatMilligrams(10 ** 3)).toBe('1g');
        expect(formatMilligrams(10 ** 4)).toBe('10g');
        expect(formatMilligrams(10 ** 5)).toBe('100g');
        expect(formatMilligrams(10 ** 6)).toBe('1kg');
        expect(formatMilligrams(10 ** 7)).toBe('10kg');
        expect(formatMilligrams(10 ** 8)).toBe('100kg');
      });

      it('formats negative numbers scaled', () => {
        expect(formatMilligrams(-12.345)).toBe('-12.345mg');
        expect(formatMilligrams(-12.345, 0)).toBe('-12mg');
        expect(formatMilligrams(-12.345, 1)).toBe('-12.3mg');
        expect(formatMilligrams(-12.345, 2)).toBe('-12.35mg');

        expect(formatMilligrams(-10)).toBe('-10mg');
        expect(formatMilligrams(-100)).toBe('-100mg');
        expect(formatMilligrams(-(10 ** 4))).toBe('-10g');
      });

      it('formats using a unit separator', () => {
        expect(formatMilligrams(1, undefined, { unitSeparator: ' ' })).toBe('1 mg');
      });
    });
  });

  describe('scaledBinaryFormatter', () => {
    describe('scaled format', () => {
      let formatScaledBin;

      beforeEach(() => {
        formatScaledBin = scaledBinaryFormatter('B');
      });

      it('formats bytes', () => {
        expect(formatScaledBin(12.345)).toBe('12.345B');
        expect(formatScaledBin(12.345, 0)).toBe('12B');
        expect(formatScaledBin(12.345, 1)).toBe('12.3B');
        expect(formatScaledBin(12.345, 2)).toBe('12.35B');
      });

      it('formats bytes in a binary scale', () => {
        expect(formatScaledBin(1)).toBe('1B');
        expect(formatScaledBin(10)).toBe('10B');
        expect(formatScaledBin(100)).toBe('100B');
        expect(formatScaledBin(1000)).toBe('1,000B');
        expect(formatScaledBin(10000)).toBe('9.766KiB');

        expect(formatScaledBin(1 * 1024)).toBe('1KiB');
        expect(formatScaledBin(10 * 1024)).toBe('10KiB');
        expect(formatScaledBin(100 * 1024)).toBe('100KiB');

        expect(formatScaledBin(1 * 1024 ** 2)).toBe('1MiB');
        expect(formatScaledBin(10 * 1024 ** 2)).toBe('10MiB');
        expect(formatScaledBin(100 * 1024 ** 2)).toBe('100MiB');

        expect(formatScaledBin(1 * 1024 ** 3)).toBe('1GiB');
        expect(formatScaledBin(10 * 1024 ** 3)).toBe('10GiB');
        expect(formatScaledBin(100 * 1024 ** 3)).toBe('100GiB');
      });

      it('formats using a unit separator', () => {
        expect(formatScaledBin(1, undefined, { unitSeparator: ' ' })).toBe('1 B');
      });
    });

    describe('scaled format with offset', () => {
      let formatGibibytes;

      beforeEach(() => {
        formatGibibytes = scaledBinaryFormatter('B', 3);
      });

      it('formats floating point numbers', () => {
        expect(formatGibibytes(12.888)).toBe('12.888GiB');
        expect(formatGibibytes(12.888, 0)).toBe('13GiB');
        expect(formatGibibytes(12.888, 1)).toBe('12.9GiB');
        expect(formatGibibytes(12.888, 2)).toBe('12.89GiB');
      });

      it('formats large numbers scaled', () => {
        expect(formatGibibytes(1)).toBe('1GiB');
        expect(formatGibibytes(10)).toBe('10GiB');
        expect(formatGibibytes(100)).toBe('100GiB');
        expect(formatGibibytes(1000)).toBe('1,000GiB');

        expect(formatGibibytes(1 * 1024)).toBe('1TiB');
        expect(formatGibibytes(10 * 1024)).toBe('10TiB');
        expect(formatGibibytes(100 * 1024)).toBe('100TiB');

        expect(formatGibibytes(1 * 1024 ** 2)).toBe('1PiB');
        expect(formatGibibytes(10 * 1024 ** 2)).toBe('10PiB');
        expect(formatGibibytes(100 * 1024 ** 2)).toBe('100PiB');

        expect(formatGibibytes(1 * 1024 ** 3)).toBe('1EiB');
        expect(formatGibibytes(10 * 1024 ** 3)).toBe('10EiB');
        expect(formatGibibytes(100 * 1024 ** 3)).toBe('100EiB');
      });

      it('formats using a unit separator', () => {
        expect(formatGibibytes(1, undefined, { unitSeparator: ' ' })).toBe('1 GiB');
      });

      it('formatting of too large numbers is not suported', () => {
        // formatting YB is out of range
        expect(() => scaledBinaryFormatter('B', 9)).toThrow();
      });
    });
  });
});
