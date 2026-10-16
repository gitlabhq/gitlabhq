import { noop } from 'lodash-es';
import { select } from 'd3-selection';
import { createPlayer, isAudioSupported } from './synth';
import { brandColors, deriveSettings, toColumns } from './utils';
import { prefersReducedMotion } from './visualizer';
import { GLOW, GLOW_COLUMNS, STRENGTH } from './shimmer';
import { createControls, svgElement } from './in_place_controls';
import {
  BRAND_FADE_MS,
  BRAND_HOLD_MS,
  COLUMNS_PER_BEAT,
  DAYS_IN_THE_WEEK,
  MIN_ACTIVE_DAYS,
  SCALES,
  VIDEO_THEME,
} from './constants';

// Plays the song on the legacy profile calendar itself, from a play button in its legend.
// Everything is drawn in a layer added to the calendar's SVG, so the calendar's own cells,
// tooltips and click handling stay untouched.
const CALENDAR_SELECTOR = '.js-contrib-calendar svg';
const WEEK_SELECTOR = '[data-testid="user-contrib-cell-group"]';
const LEGEND_SELECTOR = '.calendar-legend svg';
const GRADIENT_ID = 'contribution-music-wake';
const PASSED_ID = 'contribution-music-passed';
const PLAYHEAD_WIDTH = 2;
// Matches the legend's squares: 13px, 2px apart, and its SVG is 3px wider than its last square.
const BUTTON_SIZE = 13;
const BUTTON_GAP = 2;
const BUTTON_OFFSET = -3;
// The legend's SVG is top-aligned in its line, 2px above its squares.
const BUTTON_STYLE = { marginTop: '2px', verticalAlign: 'top' };

const emptyDay = () => ({ date: null, count: 0, level: 0 });

// The legacy calendar draws one column per week, back 12 months from today, so its first and
// last weeks are usually partial, and it can show 53 or 54 weeks. Reading its own columns keeps
// the song in step with what's on screen. d3 keeps each day's data on its rect.
const readCalendar = (svg, firstDayOfWeek) =>
  [...svg.querySelectorAll(WEEK_SELECTOR)].map((group) => {
    const { e: x, f: y } = group.transform.baseVal.consolidate().matrix;
    const cells = [...group.querySelectorAll('rect')];
    const days = Array.from({ length: DAYS_IN_THE_WEEK }, emptyDay);

    cells.forEach((cell) => {
      const { date, count, day } = select(cell).datum();
      const row = (day - firstDayOfWeek + DAYS_IN_THE_WEEK) % DAYS_IN_THE_WEEK;

      days[row] = { date, count, level: Number(cell.dataset.level) };
    });

    return { x, y, cells, days };
  });

// Copies of the lit cells, for layers drawn over the calendar's own.
const litCells = (weeks, attributes) =>
  weeks.flatMap(({ x, y, cells }) =>
    cells
      .filter((cell) => Number(cell.dataset.level) > 0)
      .map((cell) =>
        svgElement('rect', {
          x,
          y: y + Number(cell.getAttribute('y')),
          width: cell.getAttribute('width'),
          height: cell.getAttribute('height'),
          rx: cell.getAttribute('rx'),
          ...attributes(Number(cell.dataset.level)),
        }),
      ),
  );

const buildWake = (weeks) => {
  const gradient = svgElement('linearGradient', {
    id: GRADIENT_ID,
    gradientUnits: 'userSpaceOnUse',
  });

  // A hard stop just past the leading edge, since the gradient's padding would otherwise
  // carry the orange ahead of the playhead.
  [...GLOW, { at: 1, color: GLOW.at(-1).color, alpha: 0 }].forEach(({ at, color, alpha = 1 }) =>
    gradient.append(svgElement('stop', { offset: at, 'stop-color': color, 'stop-opacity': alpha })),
  );

  const cells = litCells(weeks, (level) => ({
    fill: `url(#${GRADIENT_ID})`,
    'fill-opacity': STRENGTH[level],
  }));

  return { gradient, cells };
};

// Days the playhead has passed keep a brand color, revealed by a clip that follows it, so the
// wake cools into the new color rather than back to the calendar's.
const buildPassed = (svg, weeks) => {
  const clip = svgElement('clipPath', { id: PASSED_ID });
  const edge = svgElement('rect', { x: 0, y: 0, width: 0, height: svg.getAttribute('height') });
  const group = svgElement('g', {
    'clip-path': `url(#${PASSED_ID})`,
    'pointer-events': 'none',
    'aria-hidden': true,
  });
  const defs = svgElement('defs');

  clip.append(edge);
  defs.append(clip);
  const colors = brandColors();

  group.append(defs, ...litCells(weeks, (level) => ({ fill: colors[level] })));

  return { group, reveal: (front) => edge.setAttribute('width', Math.max(front, 0)) };
};

const setUp = (svg, legend, { firstDayOfWeek, onOpen }) => {
  const weeks = readCalendar(svg, firstDayOfWeek);
  const weekDays = weeks.map(({ days }) => days);
  const activeDays = weekDays.flat().filter(({ count }) => count > 0).length;

  if (weeks.length < 2 || activeDays < MIN_ACTIVE_DAYS) {
    return noop;
  }

  const step = weeks[1].x - weeks[0].x;
  const top = Math.min(...weeks.map(({ y }) => y));
  const height = DAYS_IN_THE_WEEK * step;

  // The run layer holds the playhead and wake; passed colors outlast it, then fade.
  let run = null;
  let passed = null;
  // Set per run, since each run draws its own playhead and wake.
  let moveTo = null;
  let isStepped = false;
  // The player's position wraps back to 0 as the song ends, which would hide every passed day.
  let farthest = 0;

  const controls = createControls({
    anchor: legend,
    size: BUTTON_SIZE,
    playMargin: BUTTON_OFFSET,
    openMargin: BUTTON_GAP,
    style: BUTTON_STYLE,
    onOpen,
  });

  const clear = () => {
    const { group } = passed;

    run?.remove();
    run = null;
    controls.setPlaying(false);
    group
      .animate([{ opacity: 1 }, { opacity: 0 }], {
        duration: BRAND_FADE_MS,
        delay: BRAND_HOLD_MS,
        fill: 'forwards',
      })
      .finished.then(() => group.remove())
      .catch(() => {});
  };

  const player = createPlayer({
    onColumn: (column) => {
      if (isStepped) {
        moveTo(weeks[column].x);
      }
    },
    onPosition: (position) => {
      if (!isStepped) {
        farthest = Math.max(farthest, position);
        moveTo(weeks[0].x + farthest * weeks.length * step);
      }
    },
    onEnd: () => {
      clear();
      controls.showOpenButton();
    },
  });

  const stop = () => {
    player.stop();
    clear();
  };

  const play = () => {
    isStepped = prefersReducedMotion();
    farthest = 0;
    const settings = deriveSettings(weekDays);
    const { intervals } = SCALES.find(({ value }) => value === settings.scale);
    const columns = toColumns({ weeks: weekDays, intervals, keyOffset: settings.musicKey });
    const playhead = svgElement('rect', {
      x: weeks[0].x - PLAYHEAD_WIDTH / 2,
      y: top,
      width: PLAYHEAD_WIDTH,
      height,
      fill: VIDEO_THEME.accent,
    });
    const wake = isStepped ? null : buildWake(weeks);

    passed?.group.remove();
    passed = buildPassed(svg, weeks);
    run = svgElement('g', { 'pointer-events': 'none', 'aria-hidden': true });

    if (wake) {
      const defs = svgElement('defs');

      defs.append(wake.gradient);
      run.append(defs, ...wake.cells);
    }

    run.append(playhead);
    svg.append(passed.group, run);

    // A narrow calendar scrolls, so keep the playhead centered in view, except near either end.
    const scroller = svg.parentElement;
    const svgLeft =
      svg.getBoundingClientRect().left -
      scroller.getBoundingClientRect().left +
      scroller.scrollLeft;

    moveTo = (front) => {
      scroller.scrollLeft = svgLeft + front - scroller.clientWidth / 2;
      // A stepped playhead sits on the week it plays, so that week counts as passed.
      passed.reveal(isStepped ? front + step : front);
      playhead.setAttribute('x', front - PLAYHEAD_WIDTH / 2);
      wake?.gradient.setAttribute('x1', front - GLOW_COLUMNS * step);
      wake?.gradient.setAttribute('x2', front);
    };

    controls.setPlaying(true);
    player.start({
      columns,
      columnsPerSecond: (settings.bpm / 60) * COLUMNS_PER_BEAT,
      loop: false,
    });
  };

  controls.button.addEventListener('click', () => (run ? stop() : play()));
  // The legend shrinks beside a long hint on narrow screens, which would wrap the button.
  Object.assign(legend.parentElement.style, { flexShrink: 0, whiteSpace: 'nowrap' });

  return () => {
    if (run) {
      stop();
    }
  };
};

// The calendar draws itself once its data arrives, which can take a retry. Returns a function
// that stops the song, for when the modal player opens.
export const initInPlacePlayer = ({ calendar, firstDayOfWeek, onOpen }) => {
  let stopPlaying = noop;

  if (!isAudioSupported()) {
    return noop;
  }

  const trySetUp = () => {
    const svg = calendar.querySelector(CALENDAR_SELECTOR);
    const legend = calendar.querySelector(LEGEND_SELECTOR);

    if (svg && legend) {
      stopPlaying = setUp(svg, legend, { firstDayOfWeek, onOpen });
    }

    return Boolean(svg && legend);
  };
  const stop = () => stopPlaying();

  if (trySetUp()) {
    return stop;
  }

  const observer = new MutationObserver(() => {
    if (trySetUp()) {
      observer.disconnect();
    }
  });

  observer.observe(calendar, { childList: true, subtree: true });

  return stop;
};
