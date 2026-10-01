import { clamp, noop } from 'lodash-es';
import AjaxCache from '~/lib/utils/ajax_cache';
import { createPlayer, isAudioSupported, midiToFrequency } from './synth';
import { buildPitches, buildWeeks, deriveSettings } from './utils';
import { DAYS_IN_THE_WEEK, SCALES, VOICES } from './constants';

// Cells of both the legacy and the Vue activity calendar, so this works whichever is on.
const CELL_SELECTOR = '.user-contrib-cell, .user-contribution-graph-cell';
const CLICKS_TO_OPEN = 5;
const CLICK_WINDOW_MS = 1000;
const TONE_SECONDS = 1.5;
const TONE_VOICE = VOICES[2];

const topOf = (element) => Math.round(element.getBoundingClientRect().top);

// Measured rather than read from markup, since the two calendars structure weeks differently.
const rowOf = (cell) => {
  const tops = [...new Set([...document.querySelectorAll(CELL_SELECTOR)].map(topOf))].sort(
    (a, b) => a - b,
  );

  return clamp(tops.indexOf(topOf(cell)), 0, DAYS_IN_THE_WEEK - 1);
};

export const listenForTrigger = ({ calendarPath, utcOffset, firstDayOfWeek, onTrigger }) => {
  let player = null;
  let settings = null;
  let streak = { cell: null, clicks: 0, at: 0 };

  // The calendar has already fetched this, so it comes from the cache.
  const loadSettings = () => {
    settings ??= AjaxCache.retrieve(calendarPath)
      .then((timestamps) => deriveSettings(buildWeeks({ timestamps, utcOffset, firstDayOfWeek })))
      .catch(() => null);

    return settings;
  };

  const playTone = async (cell, step) => {
    const derived = await loadSettings();
    const scale = derived?.scale ?? SCALES[0].value;
    const { intervals } = SCALES.find(({ value }) => value === scale);
    const pitches = buildPitches({
      intervals,
      keyOffset: derived?.musicKey ?? 0,
      degreeOffset: step,
    });

    player ??= createPlayer({ onColumn: noop, onPosition: noop, onEnd: noop });
    player.start({
      columns: [[{ frequency: midiToFrequency(pitches[rowOf(cell)]), voice: TONE_VOICE }]],
      columnsPerSecond: 1 / TONE_SECONDS,
      loop: false,
    });
  };

  // Every click on a day plays its note. Quick repeats on the same day climb the scale, and
  // the fifth in a row opens the player.
  document.addEventListener('click', (event) => {
    const cell = event.target.closest?.(CELL_SELECTOR);

    if (!cell || cell.getAttribute('aria-hidden') === 'true') {
      return;
    }

    const now = performance.now();
    const isStreak = cell === streak.cell && now - streak.at < CLICK_WINDOW_MS;
    const clicks = isStreak ? streak.clicks + 1 : 1;

    streak = { cell, clicks, at: now };

    if (isAudioSupported()) {
      playTone(cell, clicks - 1);
    }

    if (clicks === CLICKS_TO_OPEN) {
      streak = { cell: null, clicks: 0, at: 0 };
      onTrigger();
    }
  });
};
