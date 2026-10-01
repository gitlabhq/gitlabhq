import { useFakeDate } from 'helpers/fake_date';
import {
  buildWeeks,
  buildPitches,
  deriveSettings,
  pickVariant,
  toColumns,
} from '~/easter_eggs/contribution_music/utils';
import { midiToFrequency } from '~/easter_eggs/contribution_music/synth';
import { VOICES } from '~/easter_eggs/contribution_music/constants';

const MAJOR_PENTATONIC = [0, 2, 4, 7, 9];

const day = (date, count = 0, level = 0) => ({ date: new Date(date), count, level });
const empty = { date: null, count: 0, level: 0 };

describe('contribution music utils', () => {
  describe('buildWeeks', () => {
    // A Monday.
    useFakeDate(2026, 8, 28);

    const flatDates = (weeks) => weeks.flat().map(({ date }) => date);

    it('covers the 12 months up to today in whole weeks', () => {
      const weeks = buildWeeks({ timestamps: {}, utcOffset: 0, firstDayOfWeek: 0 });
      const dates = flatDates(weeks).filter(Boolean);

      expect(weeks).toHaveLength(53);
      expect(weeks.every((week) => week.length === 7)).toBe(true);
      expect(dates[0]).toEqual(new Date(2025, 8, 28));
      expect(dates.at(-1)).toEqual(new Date(2026, 8, 28));
    });

    it('leaves the days after today empty', () => {
      const weeks = buildWeeks({ timestamps: {}, utcOffset: 0, firstDayOfWeek: 0 });

      expect(weeks.at(-1).slice(2)).toEqual(Array(5).fill(empty));
    });

    it('leaves the days before the 12 months empty when the week starts earlier', () => {
      const weeks = buildWeeks({ timestamps: {}, utcOffset: 0, firstDayOfWeek: 1 });

      expect(weeks[0].slice(0, 6)).toEqual(Array(6).fill(empty));
      expect(weeks[0][6].date).toEqual(new Date(2025, 8, 28));
      expect(weeks.at(-1)[0].date).toEqual(new Date(2026, 8, 28));
    });

    it('reads counts and levels from the timestamps', () => {
      const weeks = buildWeeks({
        timestamps: { '2026-09-01': 12, '2026-09-02': 30 },
        utcOffset: 0,
        firstDayOfWeek: 0,
      });
      const cells = weeks.flat();
      const find = (date) => cells.find((cell) => cell.date?.getTime() === date.getTime());

      expect(find(new Date(2026, 8, 1))).toMatchObject({ count: 12, level: 2 });
      expect(find(new Date(2026, 8, 2))).toMatchObject({ count: 30, level: 4 });
      expect(find(new Date(2026, 8, 3))).toMatchObject({ count: 0, level: 0 });
    });
  });

  describe('buildPitches', () => {
    it('puts the lowest pitch on the bottom row, two scale degrees apart', () => {
      expect(buildPitches({ intervals: MAJOR_PENTATONIC, keyOffset: 0 })).toEqual([
        76, 72, 67, 62, 57, 52, 48,
      ]);
    });

    it.each`
      keyOffset | bottom
      ${6}      | ${54}
      ${7}      | ${43}
    `('keeps key offset $keyOffset within a tritone of the root', ({ keyOffset, bottom }) => {
      expect(buildPitches({ intervals: MAJOR_PENTATONIC, keyOffset }).at(-1)).toBe(bottom);
    });

    it('shifts down across the octave for a negative degree offset', () => {
      expect(
        buildPitches({ intervals: MAJOR_PENTATONIC, keyOffset: 0, degreeOffset: -1 }).at(-1),
      ).toBe(45);
    });
  });

  describe('deriveSettings', () => {
    const march = (level) =>
      Array.from({ length: 7 }, (_, index) => day(`2026-03-0${index + 1}`, level * 10, level));
    const quietApril = Array.from({ length: 7 }, (_, index) => day(`2026-04-0${index + 1}`));

    it('returns null without any contributions', () => {
      expect(deriveSettings([quietApril, [empty]])).toBeNull();
    });

    it('takes the key from the busiest month', () => {
      expect(deriveSettings([march(1), quietApril]).musicKey).toBe(2);
    });

    it.each`
      level | scale
      ${1}  | ${'minorPentatonic'}
      ${2}  | ${'yo'}
      ${3}  | ${'majorPentatonic'}
    `('picks $scale for level $level days', ({ level, scale }) => {
      expect(deriveSettings([march(level), quietApril]).scale).toBe(scale);
    });

    it('slows down as the calendar fills up', () => {
      expect(deriveSettings([march(1), quietApril]).bpm).toBe(99);
      expect(deriveSettings([[day('2026-03-01', 1, 1)], ...Array(3).fill(quietApril)]).bpm).toBe(
        204,
      );
    });

    it('ignores days outside the calendar', () => {
      expect(deriveSettings([march(1), quietApril, [empty, empty]])).toEqual(
        deriveSettings([march(1), quietApril]),
      );
    });
  });

  describe('pickVariant', () => {
    it.each`
      seed              | variant
      ${''}             | ${'a'}
      ${'clavimoniere'} | ${'b'}
      ${'root'}         | ${'c'}
    `('picks $variant for "$seed"', ({ seed, variant }) => {
      expect(pickVariant(['a', 'b', 'c'], seed)).toBe(variant);
    });
  });

  describe('toColumns', () => {
    const quiet = Array(7).fill(day('2026-03-01'));
    const light = [...quiet.slice(0, 6), day('2026-03-07', 1, 1)];
    const busy = [
      day('2026-03-08', 30, 4),
      ...quiet.slice(0, 2),
      day('2026-03-11', 5, 1),
      ...quiet.slice(0, 3),
    ];

    const columns = () =>
      toColumns({ weeks: [light, quiet, busy], intervals: MAJOR_PENTATONIC, keyOffset: 0 });

    it('plays nothing for a week without contributions', () => {
      expect(columns()[1]).toEqual([]);
    });

    it('shifts quieter weeks down and busier weeks up', () => {
      const [lightColumn, , busyColumn] = columns();

      expect(lightColumn).toEqual([
        { frequency: midiToFrequency(45), voice: VOICES[1], columnGain: 1 },
      ]);
      expect(busyColumn).toEqual([
        { frequency: midiToFrequency(79), voice: VOICES[4], columnGain: 1 / Math.sqrt(2) },
        { frequency: midiToFrequency(64), voice: VOICES[1], columnGain: 1 / Math.sqrt(2) },
      ]);
    });
  });
});
