import { setLanguage } from 'helpers/locale_helper';
import { createDateTimeFormat, formatNumber, languageCode } from '~/locale';

describe('locale', () => {
  afterEach(() => setLanguage(null));

  describe('languageCode', () => {
    it('parses the lang attribute', () => {
      setLanguage('ja');

      expect(languageCode()).toBe('ja');
    });

    it('falls back to English', () => {
      setLanguage(null);

      expect(languageCode()).toBe('en');
    });
  });

  describe('createDateTimeFormat', () => {
    beforeEach(() => setLanguage('en'));

    it('creates an instance of Intl.DateTimeFormat', () => {
      const dateFormat = createDateTimeFormat({ year: 'numeric', month: 'long', day: 'numeric' });

      expect(dateFormat.format(new Date(2015, 6, 3))).toBe('July 3, 2015');
    });
  });

  describe('formatNumber', () => {
    it('formats numbers', () => {
      expect(formatNumber(1)).toBe('1');
      expect(formatNumber(12345)).toBe('12,345');
    });

    it('formats bigint numbers', () => {
      expect(formatNumber(123456789123456789n)).toBe('123,456,789,123,456,789');
    });

    it('formats numbers with options', () => {
      expect(formatNumber(1, { style: 'percent' })).toBe('100%');
      expect(formatNumber(1, { style: 'currency', currency: 'USD' })).toBe('$1.00');
    });

    it('formats localized numbers', () => {
      expect(formatNumber(12345, {}, 'es')).toBe('12.345');
    });

    it('formats NaN', () => {
      expect(formatNumber(NaN)).toBe('NaN');
    });

    it('formats infinity', () => {
      expect(formatNumber(Number.POSITIVE_INFINITY)).toBe('∞');
    });

    it('formats negative infinity', () => {
      expect(formatNumber(Number.NEGATIVE_INFINITY)).toBe('-∞');
    });

    it('formats EPSILON', () => {
      expect(formatNumber(Number.EPSILON)).toBe('0');
    });

    describe('non-number values should pass through', () => {
      it('undefined', () => {
        expect(formatNumber(undefined)).toBe(undefined);
      });

      it('null', () => {
        expect(formatNumber(null)).toBe(null);
      });

      it('arrays', () => {
        expect(formatNumber([])).toEqual([]);
      });

      it('objects', () => {
        expect(formatNumber({ a: 'b' })).toEqual({ a: 'b' });
      });
    });

    describe('when in a different locale', () => {
      beforeEach(() => {
        setLanguage('es');
      });

      it('formats localized numbers', () => {
        expect(formatNumber(12345)).toBe('12.345');
      });
    });
  });
});
