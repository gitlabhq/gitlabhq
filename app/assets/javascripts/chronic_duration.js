/*
 * NOTE:
 * Changes to this file should be kept in sync with
 * https://gitlab.com/gitlab-org/gitlab-chronic-duration/-/blob/master/lib/gitlab_chronic_duration.rb.
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

export class DurationParseError extends Error {}

// On average, there's a little over 4 weeks in month.
const FULL_WEEKS_PER_MONTH = 4;

const HOURS_PER_DAY = 24;
const DAYS_PER_MONTH = 30;

const FLOAT_MATCHER = /[0-9]*\.?[0-9]+/g;
const DURATION_UNITS_LIST = ['seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years'];

const MAPPINGS = {
  seconds: 'seconds',
  second: 'seconds',
  secs: 'seconds',
  sec: 'seconds',
  s: 'seconds',
  minutes: 'minutes',
  minute: 'minutes',
  mins: 'minutes',
  min: 'minutes',
  m: 'minutes',
  hours: 'hours',
  hour: 'hours',
  hrs: 'hours',
  hr: 'hours',
  h: 'hours',
  days: 'days',
  day: 'days',
  dy: 'days',
  d: 'days',
  weeks: 'weeks',
  week: 'weeks',
  wks: 'weeks',
  wk: 'weeks',
  w: 'weeks',
  months: 'months',
  mo: 'months',
  mos: 'months',
  month: 'months',
  years: 'years',
  year: 'years',
  yrs: 'years',
  yr: 'years',
  y: 'years',
};

const JOIN_WORDS = ['and', 'with', 'plus'];

function convertToNumber(string) {
  const f = parseFloat(string);
  return f % 1 > 0 ? f : parseInt(string, 10);
}

function durationUnitsSecondsMultiplier(unit, opts) {
  if (!DURATION_UNITS_LIST.includes(unit)) {
    return 0;
  }

  const hoursPerDay = opts.hoursPerDay || HOURS_PER_DAY;
  const daysPerMonth = opts.daysPerMonth || DAYS_PER_MONTH;
  const daysPerWeek = Math.trunc(daysPerMonth / FULL_WEEKS_PER_MONTH);

  switch (unit) {
    case 'years':
      return 31557600;
    case 'months':
      return 3600 * hoursPerDay * daysPerMonth;
    case 'weeks':
      return 3600 * hoursPerDay * daysPerWeek;
    case 'days':
      return 3600 * hoursPerDay;
    case 'hours':
      return 3600;
    case 'minutes':
      return 60;
    case 'seconds':
      return 1;
    default:
      return 0;
  }
}

function calculateFromWords(string, opts) {
  let val = 0;
  const words = string.split(' ');
  words.forEach((v, k) => {
    if (v === '') {
      return;
    }
    if (v.search(FLOAT_MATCHER) >= 0) {
      val +=
        convertToNumber(v) *
        durationUnitsSecondsMultiplier(
          words[parseInt(k, 10) + 1] || opts.defaultUnit || 'seconds',
          opts,
        );
    }
  });
  return val;
}

// Parse 3:41:59 and return 3 hours 41 minutes 59 seconds
function filterByType(string) {
  const chronoUnitsList = DURATION_UNITS_LIST.filter((v) => v !== 'weeks');
  if (
    string
      .replace(/ +/g, '')
      .search(RegExp(`${FLOAT_MATCHER.source}(:${FLOAT_MATCHER.source})+`, 'g')) >= 0
  ) {
    const res = [];
    string
      .replace(/ +/g, '')
      .split(':')
      .reverse()
      .forEach((v, k) => {
        if (!chronoUnitsList[k]) {
          return;
        }
        res.push(`${v} ${chronoUnitsList[k]}`);
      });
    return res.reverse().join(' ');
  }
  return string;
}

// Get rid of unknown words and map found
// words to defined time units
function filterThroughWhiteList(string, opts) {
  const res = [];
  string.split(' ').forEach((word) => {
    if (word === '') {
      return;
    }
    if (word.search(FLOAT_MATCHER) >= 0) {
      res.push(word.trim());
      return;
    }
    const strippedWord = word.trim().replace(/^,/g, '').replace(/,$/g, '');
    if (MAPPINGS[strippedWord] !== undefined) {
      res.push(MAPPINGS[strippedWord]);
    } else if (!JOIN_WORDS.includes(strippedWord) && opts.raiseExceptions) {
      throw new DurationParseError(
        `An invalid word ${JSON.stringify(word)} was used in the string to be parsed.`,
      );
    }
  });
  // add '1' at front if string starts with something recognizable but not with a number, like 'day' or 'minute 30sec'
  if (res.length > 0 && MAPPINGS[res[0]]) {
    res.splice(0, 0, 1);
  }
  return res.join(' ');
}

function cleanup(string, opts) {
  let res = string.toLowerCase();
  /*
   * TODO The Ruby implementation of this algorithm uses the Numerizer module,
   * which converts strings like "forty two" to "42", but there is no
   * JavaScript equivalent of Numerizer. Skip it for now until Numerizer is
   * ported to JavaScript.
   */
  res = filterByType(res);
  res = res
    .replace(FLOAT_MATCHER, (n) => ` ${n} `)
    .replace(/ +/g, ' ')
    .trim();
  return filterThroughWhiteList(res, opts);
}

// eslint-disable-next-line max-params
function humanizeTimeUnit(number, unit, pluralize, keepZero) {
  if (number === '0' && !keepZero) {
    return null;
  }
  let res = number + unit;
  // A poor man's pluralizer
  if (number !== '1' && pluralize) {
    res += 's';
  }
  return res;
}

// Given a string representation of elapsed time,
// return an integer (or float, if fractions of a
// second are input)
export function parseChronicDuration(string, opts = {}) {
  const result = calculateFromWords(cleanup(string, opts), opts);
  return !opts.keepZero && result === 0 ? null : result;
}

// Given an integer and an optional format,
// returns a formatted string representing elapsed time
export function outputChronicDuration(seconds, opts = {}) {
  const units = {
    years: 0,
    months: 0,
    weeks: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds,
  };

  const hoursPerDay = opts.hoursPerDay || HOURS_PER_DAY;
  const daysPerMonth = opts.daysPerMonth || DAYS_PER_MONTH;
  const daysPerWeek = Math.trunc(daysPerMonth / FULL_WEEKS_PER_MONTH);

  const decimalPlaces =
    seconds % 1 !== 0 ? seconds.toString().split('.').reverse()[0].length : null;

  const minute = 60;
  const hour = 60 * minute;
  const day = hoursPerDay * hour;
  const month = daysPerMonth * day;
  const year = 31557600;

  if (units.seconds >= 31557600 && units.seconds % year < units.seconds % month) {
    units.years = Math.trunc(units.seconds / year);
    units.months = Math.trunc((units.seconds % year) / month);
    units.days = Math.trunc(((units.seconds % year) % month) / day);
    units.hours = Math.trunc((((units.seconds % year) % month) % day) / hour);
    units.minutes = Math.trunc(((((units.seconds % year) % month) % day) % hour) / minute);
    units.seconds = Math.trunc(((((units.seconds % year) % month) % day) % hour) % minute);
  } else if (seconds >= 60) {
    units.minutes = Math.trunc(seconds / 60);
    units.seconds %= 60;
    if (units.minutes >= 60) {
      units.hours = Math.trunc(units.minutes / 60);
      units.minutes = Math.trunc(units.minutes % 60);
      if (!opts.limitToHours) {
        if (units.hours >= hoursPerDay) {
          units.days = Math.trunc(units.hours / hoursPerDay);
          units.hours = Math.trunc(units.hours % hoursPerDay);
          if (opts.weeks) {
            if (units.days >= daysPerWeek) {
              units.weeks = Math.trunc(units.days / daysPerWeek);
              units.days = Math.trunc(units.days % daysPerWeek);
              if (units.weeks >= FULL_WEEKS_PER_MONTH) {
                units.months = Math.trunc(units.weeks / FULL_WEEKS_PER_MONTH);
                units.weeks = Math.trunc(units.weeks % FULL_WEEKS_PER_MONTH);
              }
            }
          } else if (units.days >= daysPerMonth) {
            units.months = Math.trunc(units.days / daysPerMonth);
            units.days = Math.trunc(units.days % daysPerMonth);
          }
        }
      }
    }
  }

  let joiner = opts.joiner || ' ';
  let process = null;

  let dividers;
  switch (opts.format) {
    case 'micro':
      dividers = {
        years: 'y',
        months: 'mo',
        weeks: 'w',
        days: 'd',
        hours: 'h',
        minutes: 'm',
        seconds: 's',
      };
      joiner = '';
      break;
    case 'short':
      dividers = {
        years: 'y',
        months: 'mo',
        weeks: 'w',
        days: 'd',
        hours: 'h',
        minutes: 'm',
        seconds: 's',
      };
      break;
    case 'long':
      dividers = {
        /* eslint-disable @gitlab/require-i18n-strings */
        years: ' year',
        months: ' month',
        weeks: ' week',
        days: ' day',
        hours: ' hour',
        minutes: ' minute',
        seconds: ' second',
        /* eslint-enable @gitlab/require-i18n-strings */
        pluralize: true,
      };
      break;
    case 'chrono':
      dividers = {
        years: ':',
        months: ':',
        weeks: ':',
        days: ':',
        hours: ':',
        minutes: ':',
        seconds: ':',
        keepZero: true,
      };
      process = (str) => {
        // Pad zeros
        // Get rid of lead off times if they are zero
        // Get rid of lead off zero
        // Get rid of trailing:
        const divider = ':';
        const processed = [];
        str.split(divider).forEach((n) => {
          if (n === '') {
            return;
          }
          // add zeros only if n is an integer
          if (n.search('\\.') >= 0) {
            processed.push(
              parseFloat(n)
                .toFixed(decimalPlaces)
                .padStart(3 + decimalPlaces, '0'),
            );
          } else {
            processed.push(n.padStart(2, '0'));
          }
        });
        return processed
          .join(divider)
          .replace(/^(00:)+/g, '')
          .replace(/^0/g, '')
          .replace(/:$/g, '');
      };
      joiner = '';
      break;
    default:
      dividers = {
        /* eslint-disable @gitlab/require-i18n-strings */
        years: ' yr',
        months: ' mo',
        weeks: ' wk',
        days: ' day',
        hours: ' hr',
        minutes: ' min',
        seconds: ' sec',
        /* eslint-enable @gitlab/require-i18n-strings */
        pluralize: true,
      };
      break;
  }

  let result = [];
  ['years', 'months', 'weeks', 'days', 'hours', 'minutes', 'seconds'].forEach((t) => {
    if (t === 'weeks' && !opts.weeks) {
      return;
    }
    let num = units[t];
    if (t === 'seconds' && num % 0 !== 0) {
      num = num.toFixed(decimalPlaces);
    } else {
      num = num.toString();
    }
    const keepZero = !dividers.keepZero && t === 'seconds' ? opts.keepZero : dividers.keepZero;
    const humanized = humanizeTimeUnit(num, dividers[t], dividers.pluralize, keepZero);
    if (humanized !== null) {
      result.push(humanized);
    }
  });

  if (opts.units) {
    result = result.slice(0, opts.units);
  }

  result = result.join(joiner);

  if (process) {
    result = process(result);
  }

  return result.length === 0 ? null : result;
}
