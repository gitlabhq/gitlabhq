import { DATE_TIME_FORMATS, localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { setLanguage } from 'jest/__helpers__/locale_helper';
import * as localeFns from '~/locale';

describe('localeDateFormat (en-US)', () => {
  const date = new Date('1983-07-09T14:15:23.123Z');
  const sameDay = new Date('1983-07-09T18:27:09.198Z');
  const sameMonth = new Date('1983-07-12T12:36:02.654Z');
  const nextYear = new Date('1984-01-10T07:47:54.947Z');

  beforeEach(() => {
    setLanguage('en-US');
    localeDateFormat.reset();
  });

  /*
  Depending on the ICU/Intl version, formatted strings might contain
  characters which aren't a normal space, e.g. U+2009 THIN SPACE in formatRange or
  U+202F NARROW NO-BREAK SPACE between time and AM/PM.

  In order for the specs to be more portable and easier to read, as git/gitlab aren't
  great at rendering these other spaces, we replace them U+0020 SPACE
   */
  function expectDateString(str) {
    // eslint-disable-next-line jest/valid-expect
    return expect(str.replace(/[\s\u2009]+/g, ' '));
  }

  describe('#asDateTime', () => {
    it('exposes a working date formatter', () => {
      expectDateString(localeDateFormat.asDateTime.format(date)).toBe('Jul 9, 1983, 2:15 PM');
      expectDateString(localeDateFormat.asDateTime.format(nextYear)).toBe('Jan 10, 1984, 7:47 AM');
    });

    it('exposes a working date range formatter', () => {
      expectDateString(localeDateFormat.asDateTime.formatRange(date, nextYear)).toBe(
        'Jul 9, 1983, 2:15 PM – Jan 10, 1984, 7:47 AM',
      );
      expectDateString(localeDateFormat.asDateTime.formatRange(date, sameMonth)).toBe(
        'Jul 9, 1983, 2:15 PM – Jul 12, 1983, 12:36 PM',
      );
      expectDateString(localeDateFormat.asDateTime.formatRange(date, sameDay)).toBe(
        'Jul 9, 1983, 2:15 – 6:27 PM',
      );
    });

    it.each([
      ['automatic', 0, '2:15 PM'],
      ['h12 preference', 1, '2:15 PM'],
      ['h24 preference', 2, '14:15'],
    ])("respects user's hourCycle preference: %s", (_, timeDisplayFormat, result) => {
      window.gon.time_display_format = timeDisplayFormat;
      expectDateString(localeDateFormat.asDateTime.format(date)).toContain(result);
      expectDateString(localeDateFormat.asDateTime.formatRange(date, nextYear)).toContain(result);
    });
  });

  describe('#asDate', () => {
    it('exposes a working date formatter', () => {
      expectDateString(localeDateFormat.asDate.format(date)).toBe('Jul 9, 1983');
      expectDateString(localeDateFormat.asDate.format(nextYear)).toBe('Jan 10, 1984');
    });

    it('exposes a working date range formatter', () => {
      expectDateString(localeDateFormat.asDate.formatRange(date, nextYear)).toBe(
        'Jul 9, 1983 – Jan 10, 1984',
      );
      expectDateString(localeDateFormat.asDate.formatRange(date, sameMonth)).toBe(
        'Jul 9 – 12, 1983',
      );
      expectDateString(localeDateFormat.asDate.formatRange(date, sameDay)).toBe('Jul 9, 1983');
    });
  });

  describe('#reset', () => {
    it('removes the cached formatters', () => {
      const spy = jest.spyOn(localeFns, 'createDateTimeFormat');

      localeDateFormat.asDate.format(date);
      localeDateFormat.asDate.format(date);
      expect(spy).toHaveBeenCalledTimes(1);

      localeDateFormat.reset();

      localeDateFormat.asDate.format(date);
      localeDateFormat.asDate.format(date);
      expect(spy).toHaveBeenCalledTimes(2);
    });
  });

  describe.each(DATE_TIME_FORMATS)('formatter for %p', (format) => {
    it('is defined', () => {
      expect(localeDateFormat[format]).toBeDefined();
      expect(localeDateFormat[format].format(date)).toBeDefined();
      expect(localeDateFormat[format].formatRange(date, nextYear)).toBeDefined();
    });

    it('getting the formatter multiple times, just calls the Intl API once', () => {
      const spy = jest.spyOn(localeFns, 'createDateTimeFormat');

      localeDateFormat[format].format(date);
      localeDateFormat[format].format(date);

      expect(spy).toHaveBeenCalledTimes(1);
    });

    it('getting the formatter memoized the correct formatter', () => {
      const spy = jest.spyOn(localeFns, 'createDateTimeFormat');

      expect(localeDateFormat[format].format(date)).toBe(localeDateFormat[format].format(date));

      expect(spy).toHaveBeenCalledTimes(1);
    });
  });
});
