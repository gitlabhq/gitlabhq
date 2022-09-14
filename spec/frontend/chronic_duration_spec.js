/*
 * NOTE:
 * Changes to this file should be kept in sync with
 * https://gitlab.com/gitlab-org/gitlab-chronic-duration/-/blob/master/spec/lib/chronic_duration_spec.rb.
 */

/*
 * This code is based on code from
 * https://gitlab.com/gitlab-org/gitlab-chronic-duration and is
 * distributed under the following license:
 *
 * MIT License
 *
 * Copyright (c) Henry Poydar
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

import {
  parseChronicDuration,
  outputChronicDuration,
  DurationParseError,
} from '~/chronic_duration';

describe('parseChronicDuration', () => {
  /*
   * TODO The Ruby implementation of this algorithm uses the Numerizer module,
   * which converts strings like "forty two" to "42", but there is no
   * JavaScript equivalent of Numerizer. Skip it for now until Numerizer is
   * ported to JavaScript.
   */
  const EXEMPLARS = {
    '1:20': 60 + 20,
    '1:20.51': 60 + 20.51,
    '4:01:01': 4 * 3600 + 60 + 1,
    '3 mins 4 sec': 3 * 60 + 4,
    '3 Mins 4 Sec': 3 * 60 + 4,
    // 'three mins four sec': 3 * 60 + 4,
    '2 hrs 20 min': 2 * 3600 + 20 * 60,
    '2h20min': 2 * 3600 + 20 * 60,
    '6 mos 1 day': 6 * 30 * 24 * 3600 + 24 * 3600,
    '1 year 6 mos 1 day': 1 * 31557600 + 6 * 30 * 24 * 3600 + 24 * 3600,
    '2.5 hrs': 2.5 * 3600,
    '47 yrs 6 mos and 4.5d': 47 * 31557600 + 6 * 30 * 24 * 3600 + 4.5 * 24 * 3600,
    // 'two hours and twenty minutes': 2 * 3600 + 20 * 60,
    // 'four hours and forty minutes': 4 * 3600 + 40 * 60,
    // 'four hours, and fourty minutes': 4 * 3600 + 40 * 60,
    '3 weeks and, 2 days': 3600 * 24 * 7 * 3 + 3600 * 24 * 2,
    '3 weeks, plus 2 days': 3600 * 24 * 7 * 3 + 3600 * 24 * 2,
    '3 weeks with 2 days': 3600 * 24 * 7 * 3 + 3600 * 24 * 2,
    '1 month': 3600 * 24 * 30,
    '2 months': 3600 * 24 * 30 * 2,
    '18 months': 3600 * 24 * 30 * 18,
    '1 year 6 months': 3600 * 24 * (365.25 + 6 * 30),
    day: 3600 * 24,
    'minute 30s': 90,
  };

  describe("when string can't be parsed", () => {
    it('returns null', () => {
      expect(parseChronicDuration('gobblygoo')).toBeNull();
    });

    it('cannot parse zero', () => {
      expect(parseChronicDuration('0')).toBeNull();
    });

    describe('when .raiseExceptions set to true', () => {
      it('raises with DurationParseError', () => {
        expect(() => parseChronicDuration('23 gobblygoos', { raiseExceptions: true })).toThrow(
          DurationParseError,
        );
      });

      it('does not raise when string is empty', () => {
        expect(parseChronicDuration('', { raiseExceptions: true })).toBeNull();
      });
    });
  });

  it('should return zero if the string parses as zero and the .keepZero option is true', () => {
    expect(parseChronicDuration('0', { keepZero: true })).toBe(0);
  });

  it('should return a float if seconds are in decimals', () => {
    expect(parseChronicDuration('12 mins 3.141 seconds')).toBeCloseTo(723.141, 4);
  });

  it('should return an integer unless the seconds are in decimals', () => {
    expect(parseChronicDuration('12 mins 3 seconds')).toBe(723);
  });

  it('should be able to parse minutes by default', () => {
    expect(parseChronicDuration('5', { defaultUnit: 'minutes' })).toBe(300);
  });

  Object.entries(EXEMPLARS).forEach(([k, v]) => {
    it(`parses a duration like ${k}`, () => {
      expect(parseChronicDuration(k)).toBe(v);
    });
  });

  describe('with .hoursPerDay and .daysPerMonth params', () => {
    it('uses provided .hoursPerDay', () => {
      expect(parseChronicDuration('1d', { hoursPerDay: 24 })).toBe(24 * 60 * 60);
      expect(parseChronicDuration('1d', { hoursPerDay: 8 })).toBe(8 * 60 * 60);
    });

    it('uses provided .daysPerMonth', () => {
      expect(parseChronicDuration('1mo', { daysPerMonth: 30 })).toBe(30 * 24 * 60 * 60);
      expect(parseChronicDuration('1mo', { daysPerMonth: 20 })).toBe(20 * 24 * 60 * 60);

      expect(parseChronicDuration('1w', { daysPerMonth: 30 })).toBe(7 * 24 * 60 * 60);
      expect(parseChronicDuration('1w', { daysPerMonth: 20 })).toBe(5 * 24 * 60 * 60);
    });

    it('uses provided both .hoursPerDay and .daysPerMonth', () => {
      expect(parseChronicDuration('1mo', { daysPerMonth: 30, hoursPerDay: 24 })).toBe(
        30 * 24 * 60 * 60,
      );
      expect(parseChronicDuration('1mo', { daysPerMonth: 20, hoursPerDay: 8 })).toBe(
        20 * 8 * 60 * 60,
      );

      expect(parseChronicDuration('1w', { daysPerMonth: 30, hoursPerDay: 24 })).toBe(
        7 * 24 * 60 * 60,
      );
      expect(parseChronicDuration('1w', { daysPerMonth: 20, hoursPerDay: 8 })).toBe(
        5 * 8 * 60 * 60,
      );
    });
  });
});

describe('outputChronicDuration', () => {
  const EXEMPLARS = {
    [60 + 20]: {
      micro: '1m20s',
      short: '1m 20s',
      default: '1 min 20 secs',
      long: '1 minute 20 seconds',
      chrono: '1:20',
    },
    [60 + 20.51]: {
      micro: '1m20.51s',
      short: '1m 20.51s',
      default: '1 min 20.51 secs',
      long: '1 minute 20.51 seconds',
      chrono: '1:20.51',
    },
    [60 + 20.51928]: {
      micro: '1m20.51928s',
      short: '1m 20.51928s',
      default: '1 min 20.51928 secs',
      long: '1 minute 20.51928 seconds',
      chrono: '1:20.51928',
    },
    [4 * 3600 + 60 + 1]: {
      micro: '4h1m1s',
      short: '4h 1m 1s',
      default: '4 hrs 1 min 1 sec',
      long: '4 hours 1 minute 1 second',
      chrono: '4:01:01',
    },
    [2 * 3600 + 20 * 60]: {
      micro: '2h20m',
      short: '2h 20m',
      default: '2 hrs 20 mins',
      long: '2 hours 20 minutes',
      chrono: '2:20',
    },
    [2 * 3600 + 20 * 60]: {
      micro: '2h20m',
      short: '2h 20m',
      default: '2 hrs 20 mins',
      long: '2 hours 20 minutes',
      chrono: '2:20:00',
    },
    [6 * 30 * 24 * 3600 + 24 * 3600]: {
      micro: '6mo1d',
      short: '6mo 1d',
      default: '6 mos 1 day',
      long: '6 months 1 day',
      chrono: '6:01:00:00:00', // Yuck. FIXME
    },
    [365.25 * 24 * 3600 + 24 * 3600]: {
      micro: '1y1d',
      short: '1y 1d',
      default: '1 yr 1 day',
      long: '1 year 1 day',
      chrono: '1:00:01:00:00:00',
    },
    [3 * 365.25 * 24 * 3600 + 24 * 3600]: {
      micro: '3y1d',
      short: '3y 1d',
      default: '3 yrs 1 day',
      long: '3 years 1 day',
      chrono: '3:00:01:00:00:00',
    },
    [3600 * 24 * 30 * 18]: {
      micro: '18mo',
      short: '18mo',
      default: '18 mos',
      long: '18 months',
      chrono: '18:00:00:00:00',
    },
  };

  Object.entries(EXEMPLARS).forEach(([k, v]) => {
    const kf = parseFloat(k);
    Object.entries(v).forEach(([key, val]) => {
      it(`properly outputs a duration of ${kf} seconds as ${val} using the ${key} format option`, () => {
        expect(outputChronicDuration(kf, { format: key })).toBe(val);
      });
    });
  });

  const KEEP_ZERO_EXEMPLARS = {
    true: {
      micro: '0s',
      short: '0s',
      default: '0 secs',
      long: '0 seconds',
      chrono: '0',
    },
    '': {
      micro: null,
      short: null,
      default: null,
      long: null,
      chrono: '0',
    },
  };

  Object.entries(KEEP_ZERO_EXEMPLARS).forEach(([k, v]) => {
    const kb = Boolean(k);
    Object.entries(v).forEach(([key, val]) => {
      it(`should properly output a duration of 0 seconds as ${val} using the ${key} format option, if the .keepZero option is ${kb}`, () => {
        expect(outputChronicDuration(0, { format: key, keepZero: kb })).toBe(val);
      });
    });
  });

  it('returns weeks when needed', () => {
    expect(outputChronicDuration(45 * 24 * 60 * 60, { weeks: true })).toMatch(/.*wk.*/);
  });

  it('returns hours and minutes only when .limitToHours option specified', () => {
    expect(outputChronicDuration(395 * 24 * 60 * 60 + 15 * 60, { limitToHours: true })).toBe(
      '9480 hrs 15 mins',
    );
  });

  describe('with .hoursPerDay and .daysPerMonth params', () => {
    it('uses provided .hoursPerDay', () => {
      expect(outputChronicDuration(24 * 60 * 60, { hoursPerDay: 24 })).toBe('1 day');
      expect(outputChronicDuration(24 * 60 * 60, { hoursPerDay: 8 })).toBe('3 days');
    });

    it('uses provided .daysPerMonth', () => {
      expect(outputChronicDuration(7 * 24 * 60 * 60, { weeks: true, daysPerMonth: 30 })).toBe(
        '1 wk',
      );
      expect(outputChronicDuration(7 * 24 * 60 * 60, { weeks: true, daysPerMonth: 20 })).toBe(
        '1 wk 2 days',
      );
    });

    it('uses provided both .hoursPerDay and .daysPerMonth', () => {
      expect(
        outputChronicDuration(7 * 24 * 60 * 60, { weeks: true, daysPerMonth: 30, hoursPerDay: 24 }),
      ).toBe('1 wk');
      expect(
        outputChronicDuration(5 * 8 * 60 * 60, { weeks: true, daysPerMonth: 20, hoursPerDay: 8 }),
      ).toBe('1 wk');
    });

    it('uses provided params alongside with .weeks when converting to months', () => {
      expect(outputChronicDuration(30 * 24 * 60 * 60, { daysPerMonth: 30, hoursPerDay: 24 })).toBe(
        '1 mo',
      );
      expect(
        outputChronicDuration(30 * 24 * 60 * 60, {
          daysPerMonth: 30,
          hoursPerDay: 24,
          weeks: true,
        }),
      ).toBe('1 mo 2 days');

      expect(outputChronicDuration(20 * 8 * 60 * 60, { daysPerMonth: 20, hoursPerDay: 8 })).toBe(
        '1 mo',
      );
      expect(
        outputChronicDuration(20 * 8 * 60 * 60, { daysPerMonth: 20, hoursPerDay: 8, weeks: true }),
      ).toBe('1 mo');
    });
  });

  it('returns the specified number of units if provided', () => {
    expect(outputChronicDuration(4 * 3600 + 60 + 1, { units: 2 })).toBe('4 hrs 1 min');
    expect(
      outputChronicDuration(6 * 30 * 24 * 3600 + 24 * 3600 + 3600 + 60 + 1, {
        units: 3,
        format: 'long',
      }),
    ).toBe('6 months 1 day 1 hour');
  });

  describe('when the format is not specified', () => {
    it('uses the default format', () => {
      expect(outputChronicDuration(2 * 3600 + 20 * 60)).toBe('2 hrs 20 mins');
    });
  });

  Object.entries(EXEMPLARS).forEach(([seconds, formatSpec]) => {
    const secondsF = parseFloat(seconds);
    Object.keys(formatSpec).forEach((format) => {
      it(`outputs a duration for ${seconds} that parses back to the same thing when using the ${format} format`, () => {
        expect(parseChronicDuration(outputChronicDuration(secondsF, { format }))).toBe(secondsF);
      });
    });
  });

  it('uses user-specified joiner if provided', () => {
    expect(outputChronicDuration(2 * 3600 + 20 * 60, { joiner: ', ' })).toBe('2 hrs, 20 mins');
  });
});

describe('work week', () => {
  it('should parse knowing the work week', () => {
    const week = parseChronicDuration('5d', { hoursPerDay: 8, daysPerMonth: 20 });
    expect(parseChronicDuration('40h', { hoursPerDay: 8, daysPerMonth: 20 })).toBe(week);
    expect(parseChronicDuration('1w', { hoursPerDay: 8, daysPerMonth: 20 })).toBe(week);
  });
});
