import { noop } from 'lodash-es';
import { select } from 'd3-selection';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { createPlayer, isAudioSupported } from './synth';
import { deriveSettings, toColumns } from './utils';
import { prefersReducedMotion } from './visualizer';
import { GLOW, GLOW_COLUMNS, STRENGTH } from './shimmer';
import {
  BRAND_COLORS,
  BRAND_FADE_MS,
  BRAND_HOLD_MS,
  COLUMNS_PER_BEAT,
  DAYS_IN_THE_WEEK,
  I18N,
  LIGHT_BRAND_COLORS,
  MIN_ACTIVE_DAYS,
  SCALES,
  VIDEO_THEME,
} from './constants';

// Plays the song on the legacy profile calendar itself, from a play button in its legend.
// Everything is drawn in a layer added to the calendar's SVG, so the calendar's own cells,
// tooltips and click handling stay untouched.
const SVG_NS = 'http://www.w3.org/2000/svg';
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
const OPEN_PULSE_MS = 6000;

const svgElement = (name, attributes = {}) => {
  const element = document.createElementNS(SVG_NS, name);

  Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));

  return element;
};

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
  const colors = darkModeEnabled() ? BRAND_COLORS : LIGHT_BRAND_COLORS;

  group.append(defs, ...litCells(weeks, (level) => ({ fill: colors[level] })));

  return { group, reveal: (front) => edge.setAttribute('width', Math.max(front, 0)) };
};

const createButton = (marginLeft) => {
  const button = document.createElement('button');
  const glyph = svgElement('svg', { width: 7, height: 7, viewBox: '0 0 7 7', 'aria-hidden': true });

  button.type = 'button';
  Object.assign(button.style, {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: `${BUTTON_SIZE}px`,
    height: `${BUTTON_SIZE}px`,
    marginLeft: `${marginLeft}px`,
    marginTop: '2px',
    verticalAlign: 'top',
    padding: 0,
    border: 0,
    borderRadius: '2px',
    backgroundColor: 'var(--user-contribution-graph-cell-level-0)',
    color: 'var(--gl-text-color-subtle)',
    cursor: 'pointer',
  });
  glyph.style.fill = 'currentColor';
  button.append(glyph);

  return { button, glyph };
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
  const { button, glyph } = createButton(BUTTON_OFFSET);
  let openButton = null;

  // The run layer holds the playhead and wake; passed colors outlast it, then fade.
  let run = null;
  let passed = null;
  // Set per run, since each run draws its own playhead and wake.
  let moveTo = null;
  let isStepped = false;
  // The player's position wraps back to 0 as the song ends, which would hide every passed day.
  let farthest = 0;

  const setPlaying = (isPlaying) => {
    button.setAttribute('aria-label', isPlaying ? I18N.stopInPlace : I18N.playInPlace);
    button.setAttribute('aria-pressed', isPlaying);
    glyph.replaceChildren(
      isPlaying
        ? svgElement('rect', { width: 6, height: 6, x: 0.5, y: 0.5 })
        : svgElement('polygon', { points: '1,0 7,3.5 1,7' }),
    );
  };

  const clear = () => {
    const { group } = passed;

    run?.remove();
    run = null;
    setPlaying(false);
    group
      .animate([{ opacity: 1 }, { opacity: 0 }], {
        duration: BRAND_FADE_MS,
        delay: BRAND_HOLD_MS,
        fill: 'forwards',
      })
      .finished.then(() => group.remove())
      .catch(() => {});
  };

  // Once the song has played through, the full player is one step away. The button fades in
  // as the brand colors fade from the calendar, and keeps cycling through them.
  const showOpenButton = () => {
    if (openButton) {
      return;
    }

    const open = createButton(BUTTON_GAP);
    const colors = (darkModeEnabled() ? BRAND_COLORS : LIGHT_BRAND_COLORS).slice(1);
    const [first] = colors;

    openButton = open.button;
    open.glyph.remove();
    openButton.setAttribute('aria-label', I18N.openPlayer);
    openButton.addEventListener('click', onOpen);
    button.after(openButton);
    openButton.animate([{ opacity: 0 }, { opacity: 1 }], {
      duration: BRAND_FADE_MS,
      delay: BRAND_HOLD_MS,
      fill: 'backwards',
    });

    if (prefersReducedMotion()) {
      openButton.style.backgroundColor = first;
    } else {
      openButton.animate(
        [...colors, first].map((backgroundColor) => ({ backgroundColor })),
        { duration: OPEN_PULSE_MS, iterations: Infinity, easing: 'ease-in-out' },
      );
    }
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
      showOpenButton();
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

    setPlaying(true);
    player.start({
      columns,
      columnsPerSecond: (settings.bpm / 60) * COLUMNS_PER_BEAT,
      loop: false,
    });
  };

  button.addEventListener('click', () => (run ? stop() : play()));
  setPlaying(false);
  legend.after(button);
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
