import { chunk, noop } from 'lodash-es';
import AjaxCache from '~/lib/utils/ajax_cache';
import { createPlayer, isAudioSupported } from './synth';
import { brandColors, buildWeeks, deriveSettings, toColumns } from './utils';
import { prefersReducedMotion } from './visualizer';
import { glowCell } from './shimmer';
import { createControls } from './in_place_controls';
import {
  BRAND_FADE_MS,
  BRAND_HOLD_MS,
  COLUMNS_PER_BEAT,
  DAYS_IN_THE_WEEK,
  MIN_ACTIVE_DAYS,
  SCALES,
  VIDEO_THEME,
} from './constants';

// Plays the song on the Vue profile calendar itself, from a play button in its legend. Its cells
// are Vue's, so they are only ever animated, never restyled or re-rendered, which leaves their
// tooltips, selection and keyboard navigation untouched. The playhead is the one added element.
const GRID_SELECTOR = '.contrib-calendar';
const CELL_SELECTOR = '.user-contribution-graph-cell';
const LEGEND_CELL_SELECTOR = '.contrib-legend-cell';
const PLAYHEAD_WIDTH = 2;

// The grid renders before its data arrives, and is busy until then.
const isLoaded = (grid) => grid.getAttribute('aria-busy') !== 'true';

// Week columns are sized in fractions of the grid, so measure them unrounded, unlike
// offsetLeft, whose rounding would add up across the year and leave the playhead behind.
const measure = (grid, cells) => {
  const origin = grid.getBoundingClientRect();
  const left = origin.left + grid.clientLeft;
  const lefts = cells.map(([cell]) => cell.getBoundingClientRect().left - left);
  const firstDay = cells[0][0].getBoundingClientRect();
  const lastDay = cells[0].at(-1).getBoundingClientRect();

  return {
    lefts,
    // Averaged over the year, so it matches the columns on average too.
    step: (lefts.at(-1) - lefts[0]) / (lefts.length - 1),
    top: firstDay.top - origin.top - grid.clientTop,
    height: lastDay.bottom - firstDay.top,
  };
};

// Positioned and sized by the run, which measures the grid.
const createPlayhead = () => {
  const playhead = document.createElement('div');

  playhead.setAttribute('aria-hidden', true);
  playhead.dataset.testid = 'contribution-music-playhead';
  Object.assign(playhead.style, {
    position: 'absolute',
    width: `${PLAYHEAD_WIDTH}px`,
    backgroundColor: VIDEO_THEME.accent,
    pointerEvents: 'none',
    // Above a hovered or selected day, which is raised to show its outline.
    zIndex: 2,
  });

  return playhead;
};

// A rule as tall as the legend's squares. The legend's own gap spaces it on either side.
const createDivider = (height) => {
  const divider = document.createElement('span');

  divider.setAttribute('aria-hidden', true);
  divider.dataset.testid = 'contribution-music-divider';
  Object.assign(divider.style, {
    flexShrink: 0,
    width: '1px',
    height: `${height}px`,
    backgroundColor: 'var(--gl-border-color-default)',
  });

  return divider;
};

const setUp = ({ grid, legendCell, weeks, onOpen }) => {
  // One cell per day, padding included, in week order, so it chunks the same as the data.
  const cells = chunk([...grid.querySelectorAll(CELL_SELECTOR)], DAYS_IN_THE_WEEK);
  const activeDays = weeks.flat().filter(({ count }) => count > 0).length;

  if (cells.length !== weeks.length || weeks.length < 2 || activeDays < MIN_ACTIVE_DAYS) {
    return noop;
  }

  const scroller = grid.parentElement;
  // Set per run, which measures the calendar as it is laid out, and again when it resizes.
  let run = null;
  // Days passed in the last run hold their brand color, then fade back.
  let fades = [];

  // After the legend's "More", the label beside its last square, set apart by a divider.
  const legend = legendCell.parentElement;
  const divider = createDivider(legendCell.offsetHeight);

  (legend.nextElementSibling ?? legend).after(divider);
  // The legend shrinks beside a long hint on narrow screens, which would wrap the buttons.
  Object.assign(legend.parentElement.style, { flexShrink: 0, whiteSpace: 'nowrap' });

  const controls = createControls({
    anchor: divider,
    size: legendCell.offsetWidth,
    radius: getComputedStyle(legendCell).borderRadius,
    onOpen,
  });

  // Measures the calendar as it is laid out now. The grid is the playhead's containing block,
  // so cells measure from it too.
  const layOut = (current) => {
    const { lefts, step, top, height } = measure(grid, cells);

    Object.assign(current, {
      lefts,
      step,
      // A narrow calendar scrolls, so keep the playhead centered in view, except near either end.
      gridLeft:
        grid.getBoundingClientRect().left -
        scroller.getBoundingClientRect().left +
        scroller.scrollLeft,
    });
    Object.assign(current.playhead.style, { top: `${top}px`, height: `${height}px` });
  };

  // Holds a passed day in its brand color until the run is cleared.
  const hold = (cell, color, current) => {
    if (current !== run) {
      return;
    }

    current.held.push({
      cell,
      color,
      animation: cell.animate([{ backgroundColor: color }], { duration: 0, fill: 'forwards' }),
    });
  };

  const shimmerWeek = (weekIndex) => {
    const current = run;

    weeks[weekIndex].forEach(({ level }, dayIndex) => {
      const cell = cells[weekIndex][dayIndex];

      if (level === 0) {
        return;
      }

      const entry = { cell, color: current.colors[level] };

      entry.animation = glowCell(cell, {
        level,
        color: entry.color,
        columnMs: current.columnMs,
        step: current.step,
        reducedMotion: current.isStepped,
      });
      // Tracked until it finishes, so a glow still running when the song ends fades too.
      current.glowing.add(entry);
      entry.animation.finished
        .then(() => {
          current.glowing.delete(entry);
          hold(cell, entry.color, current);
        })
        .catch(noop);
    });
  };

  const clear = () => {
    const { playhead, held, glowing, resizeObserver } = run;

    run = null;
    resizeObserver.disconnect();
    playhead.remove();
    controls.setPlaying(false);
    fades = [...held, ...glowing].map(({ cell, color, animation }) => {
      animation.cancel();

      return cell.animate([{ backgroundColor: color, offset: 0 }], {
        duration: BRAND_FADE_MS,
        delay: BRAND_HOLD_MS,
        fill: 'backwards',
      });
    });
  };

  const player = createPlayer({
    onColumn: (column) => {
      // Callbacks can still fire after stop, when the player's async start resolves late.
      if (!run) {
        return;
      }

      run.column = column;

      if (run.isStepped) {
        run.moveTo(run.lefts[column]);
      }

      shimmerWeek(column);
    },
    onPosition: (position) => {
      if (!run || run.isStepped) {
        return;
      }

      // The player's position wraps back to 0 as the song ends.
      run.farthest = Math.max(run.farthest, position);
      run.moveTo(run.frontAt(run.farthest));
    },
    onEnd: () => {
      if (!run) {
        return;
      }

      clear();
      controls.showOpenButton();
    },
  });

  const stop = () => {
    player.stop();
    clear();
  };

  const play = () => {
    const settings = deriveSettings(weeks);
    const { intervals } = SCALES.find(({ value }) => value === settings.scale);
    const columns = toColumns({ weeks, intervals, keyOffset: settings.musicKey });
    const columnsPerSecond = (settings.bpm / 60) * COLUMNS_PER_BEAT;

    fades.forEach((fade) => fade.cancel());
    fades = [];

    const playhead = createPlayhead();
    const current = {
      playhead,
      colors: brandColors(),
      columnMs: 1000 / columnsPerSecond,
      isStepped: prefersReducedMotion(),
      farthest: 0,
      column: 0,
      held: [],
      glowing: new Set(),
      // Within each week, so the playhead reaches every column as its notes play.
      frontAt: (position) => {
        const at = position * weeks.length;
        const week = Math.min(Math.floor(at), current.lefts.length - 1);

        return current.lefts[week] + (at - week) * current.step;
      },
      moveTo: (front) => {
        scroller.scrollLeft = current.gridLeft + front - scroller.clientWidth / 2;
        playhead.style.left = `${front - PLAYHEAD_WIDTH / 2}px`;
      },
    };

    grid.append(playhead);
    layOut(current);
    playhead.style.left = `${current.lefts[0] - PLAYHEAD_WIDTH / 2}px`;

    // The grid is fluid, so a resize mid-song (the window, or the sidebar) moves its columns.
    current.resizeObserver = new ResizeObserver(() => {
      layOut(current);
      current.moveTo(
        current.isStepped ? current.lefts[current.column] : current.frontAt(current.farthest),
      );
    });
    current.resizeObserver.observe(grid);
    run = current;

    controls.setPlaying(true);
    player.start({ columns, columnsPerSecond, loop: false });
  };

  // The playhead's containing block. Object.assign, since `grid` is a parameter
  // (no-param-reassign).
  Object.assign(grid.style, { position: 'relative' });
  controls.button.addEventListener('click', () => (run ? stop() : play()));

  return () => {
    if (run) {
      stop();
    }
  };
};

// Vue replaces the calendar's mount point, so this watches its parent for the calendar, which
// is ready once its data has loaded, possibly after a retry. Returns a function that stops the
// song, for when the modal player opens.
export const initVueInPlacePlayer = ({
  container,
  calendarPath,
  utcOffset,
  firstDayOfWeek,
  onOpen,
}) => {
  if (!container || !isAudioSupported()) {
    return noop;
  }

  let weeks = null;
  let stopPlaying = noop;
  let isSetUp = false;
  let isFetching = false;

  const trySetUp = (watcher) => {
    const grid = container.querySelector(GRID_SELECTOR);
    const legendCell = [...container.querySelectorAll(LEGEND_CELL_SELECTOR)].at(-1);

    if (!isSetUp && weeks && grid && legendCell && isLoaded(grid)) {
      isSetUp = true;
      stopPlaying = setUp({ grid, legendCell, weeks, onOpen });
      watcher.disconnect();
    }
  };

  // The calendar fetches this too, so only one request goes out. After a failed load the
  // calendar's own retry caches the data, so fetching again then sends no request.
  const fetchWeeks = (watcher) => {
    isFetching = true;

    AjaxCache.retrieve(calendarPath)
      .then((timestamps) => {
        weeks = buildWeeks({ timestamps, utcOffset, firstDayOfWeek });
        trySetUp(watcher);
      })
      // Keep watching: on error the calendar removes its grid and offers a retry.
      .catch(noop)
      .finally(() => {
        isFetching = false;
      });
  };

  const observer = new MutationObserver((mutations, watcher) => {
    const grid = container.querySelector(GRID_SELECTOR);

    // The grid is back and loaded after a retry, but the first fetch failed.
    if (!weeks && !isFetching && grid && isLoaded(grid)) {
      fetchWeeks(watcher);
      return;
    }

    trySetUp(watcher);
  });

  observer.observe(container, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['aria-busy'],
  });

  fetchWeeks(observer);

  return () => stopPlaying();
};
