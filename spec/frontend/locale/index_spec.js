import { setLanguage } from 'helpers/locale_helper';
import { createDateTimeFormat, formatNumber, languageCode, getPreferredLocales } from '~/locale';

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

  describe('getPreferredLocales', () => {
    beforeEach(() => {
      // Need to spy on window.navigator.languages as it is read-only
      jest
        .spyOn(window.navigator, 'languages', 'get')
        .mockReturnValueOnce(['en-GB', 'en-US', 'de-AT']);
    });

    it('filters navigator.languages by GitLab language', () => {
      setLanguage('en');

      expect(getPreferredLocales()).toEqual(['en-GB', 'en-US', 'en']);
    });

    it('filters navigator.languages by GitLab language without locale and sets English Fallback', () => {
      setLanguage('de');

      expect(getPreferredLocales()).toEqual(['de-AT', 'de', 'en']);
    });

    it('filters navigator.languages by GitLab language with locale and sets English Fallback', () => {
      setLanguage('de-DE');

      expect(getPreferredLocales()).toEqual(['de-AT', 'de-DE', 'de', 'en']);
    });

    it('adds GitLab language if navigator.languages does not contain it', () => {
      setLanguage('es-ES');

      expect(getPreferredLocales()).toEqual(['es-ES', 'es', 'en']);
    });
  });

  describe('createDateTimeFormat', () => {
    const date = new Date(2015, 0, 3, 15, 13, 22);
    const formatOptions = { dateStyle: 'long', timeStyle: 'medium' };

    it('creates an instance of Intl.DateTimeFormat', () => {
      const dateFormat = createDateTimeFormat(formatOptions);

      expect(dateFormat).toBeInstanceOf(Intl.DateTimeFormat);
    });

    it('falls back to `en` and GitLab language is default', () => {
      setLanguage(null);
      jest.spyOn(window.navigator, 'languages', 'get').mockReturnValueOnce(['de-AT', 'en-GB']);

      const dateFormat = createDateTimeFormat(formatOptions);
      expect(dateFormat.format(date)).toBe(
        new Intl.DateTimeFormat('en-GB', formatOptions).format(date),
      );
    });

    it('falls back to `en` locale if browser languages are empty', () => {
      setLanguage('en');
      jest.spyOn(window.navigator, 'languages', 'get').mockReturnValueOnce([]);

      const dateFormat = createDateTimeFormat(formatOptions);
      expect(dateFormat.format(date)).toBe(
        new Intl.DateTimeFormat('en', formatOptions).format(date),
      );
    });

    it('prefers `en-GB` if it is the preferred language and GitLab language is `en`', () => {
      setLanguage('en');
      jest
        .spyOn(window.navigator, 'languages', 'get')
        .mockReturnValueOnce(['en-GB', 'en-US', 'en']);

      const dateFormat = createDateTimeFormat(formatOptions);
      expect(dateFormat.format(date)).toBe(
        new Intl.DateTimeFormat('en-GB', formatOptions).format(date),
      );
    });

    it('prefers `de-AT` if it is GitLab language and not part of the browser languages', () => {
      setLanguage('de-AT');
      jest
        .spyOn(window.navigator, 'languages', 'get')
        .mockReturnValueOnce(['en-GB', 'en-US', 'en']);

      const dateFormat = createDateTimeFormat(formatOptions);
      expect(dateFormat.format(date)).toBe(
        new Intl.DateTimeFormat('de-AT', formatOptions).format(date),
      );
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
