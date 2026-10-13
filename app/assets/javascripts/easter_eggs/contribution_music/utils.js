import { times, chunk, clamp } from 'lodash-es';
import { CONTRIB_LEGENDS } from '~/contribution_events/constants';
import {
  getCurrentDateAtOffset,
  nDaysAfter,
  nDaysBefore,
  nMonthsBefore,
  getDatesInRange,
  toISODateFormat,
} from '~/lib/utils/datetime_utility';
import { midiToFrequency } from './synth';
import {
  DAYS_IN_THE_WEEK,
  VOICES,
  ROOT_MIDI,
  SCALES,
  BRIGHTEST_AT_LEVEL,
  SPARSEST_DENSITY,
  DENSEST_DENSITY,
  DERIVED_MIN_BPM,
  DERIVED_MAX_BPM,
  MONTHS_IN_THE_YEAR,
  SEMITONES_IN_OCTAVE,
  ROW_STEP,
  WEEK_SHIFT_DEGREES,
} from './constants';

const DERIVABLE_SCALES = SCALES.filter(({ anhemitonic }) => anhemitonic).sort(
  (a, b) => a.brightness - b.brightness,
);

const centeredKeyOffset = (keyOffset) =>
  keyOffset > SEMITONES_IN_OCTAVE / 2 ? keyOffset - SEMITONES_IN_OCTAVE : keyOffset;

const levelFor = (count) => CONTRIB_LEGENDS.findLast(({ min }) => count >= min)?.level ?? 0;

export const buildWeeks = ({ timestamps, utcOffset, firstDayOfWeek }) => {
  const today = getCurrentDateAtOffset(utcOffset);

  const daysLeftInWeek =
    DAYS_IN_THE_WEEK -
    1 -
    ((today.getDay() - firstDayOfWeek + DAYS_IN_THE_WEEK) % DAYS_IN_THE_WEEK);
  const lastDay = nDaysAfter(today, daysLeftInWeek);
  // The same 12 months as the profile calendar, so both play the same song.
  const yearAgo = nMonthsBefore(today, MONTHS_IN_THE_YEAR);
  const firstDay = nDaysBefore(
    yearAgo,
    (yearAgo.getDay() - firstDayOfWeek + DAYS_IN_THE_WEEK) % DAYS_IN_THE_WEEK,
  );

  const cells = getDatesInRange(firstDay, lastDay).map((date) => {
    if (date < yearAgo || date > today) {
      return { date: null, count: 0, level: 0 };
    }

    const count = timestamps[toISODateFormat(date)] || 0;

    return { date, count, level: levelFor(count) };
  });

  return chunk(cells, DAYS_IN_THE_WEEK);
};

export const buildPitches = ({ intervals, keyOffset, degreeOffset = 0 }) =>
  times(DAYS_IN_THE_WEEK, (index) => {
    const degree = index * ROW_STEP + degreeOffset;
    const octave = Math.floor(degree / intervals.length);
    const step = degree - octave * intervals.length;

    return (
      ROOT_MIDI + centeredKeyOffset(keyOffset) + octave * SEMITONES_IN_OCTAVE + intervals[step]
    );
  }).reverse();

const busiestMonth = (days) => {
  const totals = times(MONTHS_IN_THE_YEAR, () => ({ count: 0, days: 0 }));

  days.forEach(({ date, count }) => {
    const month = totals[date.getMonth()];

    month.count += count;
    month.days += 1;
  });

  const means = totals.map(({ count, days: dayCount }) => (dayCount ? count / dayCount : 0));

  return means.indexOf(Math.max(...means));
};

export const deriveSettings = (weeks) => {
  const days = weeks.flat().filter(({ date }) => date !== null);
  const active = days.filter(({ count }) => count > 0);

  if (!active.length) {
    return null;
  }

  const meanLevel = active.reduce((total, { level }) => total + level, 0) / active.length;
  const brightness = clamp((meanLevel - 1) / (BRIGHTEST_AT_LEVEL - 1), 0, 1);

  const density = clamp(
    (active.length / days.length - SPARSEST_DENSITY) / (DENSEST_DENSITY - SPARSEST_DENSITY),
    0,
    1,
  );

  const scale = DERIVABLE_SCALES[Math.round(brightness * (DERIVABLE_SCALES.length - 1))].value;

  return {
    musicKey: busiestMonth(days),
    scale,
    bpm: Math.round(DERIVED_MIN_BPM + (1 - density) ** 2 * (DERIVED_MAX_BPM - DERIVED_MIN_BPM)),
  };
};

export const pickVariant = (variants, seed) => {
  const hash = [...seed].reduce((total, char) => Math.imul(total, 31) + char.codePointAt(0), 0);

  return variants[Math.abs(hash) % variants.length];
};

const columnGain = (count) => 1 / Math.sqrt(Math.max(count, 1));

const weekTotal = (week) => week.reduce((total, { count }) => total + count, 0);

const weekShifts = (weeks) => {
  const totals = weeks.map(weekTotal);
  const active = totals.filter((total) => total > 0);

  return totals.map((total) => {
    if (!total) {
      return 0;
    }

    const below = active.filter((other) => other < total).length;
    const tied = active.filter((other) => other === total).length;
    const rank = (below + tied / 2) / active.length;

    return Math.round((rank - 0.5) * WEEK_SHIFT_DEGREES);
  });
};

export const toColumns = ({ weeks, intervals, keyOffset }) => {
  const shifts = weekShifts(weeks);

  return weeks.map((week, index) => {
    const gain = columnGain(week.filter(({ level }) => level > 0).length);
    const pitches = buildPitches({ intervals, keyOffset, degreeOffset: shifts[index] });

    return week.flatMap(({ level }, dayIndex) =>
      level > 0
        ? [
            {
              frequency: midiToFrequency(pitches[dayIndex]),
              voice: VOICES[level],
              columnGain: gain,
            },
          ]
        : [],
    );
  });
};
