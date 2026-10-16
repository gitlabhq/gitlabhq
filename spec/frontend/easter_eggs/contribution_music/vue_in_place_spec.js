import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useMockResizeObserver } from 'helpers/mock_dom_observer';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AjaxCache from '~/lib/utils/ajax_cache';
import { nDaysBefore, toISODateFormat } from '~/lib/utils/datetime_utility';
import { initVueActivityCalendar } from '~/pages/users/vue_activity_calendar';
import { initVueInPlacePlayer } from '~/easter_eggs/contribution_music/vue_in_place';
import { createPlayer } from '~/easter_eggs/contribution_music/synth';
import { glowCell } from '~/easter_eggs/contribution_music/shimmer';
import { buildWeeks } from '~/easter_eggs/contribution_music/utils';
import {
  BRAND_FADE_MS,
  BRAND_HOLD_MS,
  MIN_ACTIVE_DAYS,
} from '~/easter_eggs/contribution_music/constants';

jest.mock('~/lib/utils/ajax_cache');

jest.mock('~/easter_eggs/contribution_music/utils', () => ({
  ...jest.requireActual('~/easter_eggs/contribution_music/utils'),
  buildWeeks: jest.fn(),
}));

const { buildWeeks: actualBuildWeeks } = jest.requireActual(
  '~/easter_eggs/contribution_music/utils',
);

jest.mock('~/easter_eggs/contribution_music/synth', () => ({
  ...jest.requireActual('~/easter_eggs/contribution_music/synth'),
  isAudioSupported: () => true,
  createPlayer: jest.fn(),
}));

jest.mock('~/easter_eggs/contribution_music/shimmer', () => ({
  ...jest.requireActual('~/easter_eggs/contribution_music/shimmer'),
  glowCell: jest.fn(),
}));

const CALENDAR_PATH = '/users/root/calendar.json';

// Recent days, so they all fall within the calendar's last 12 months.
const timestampsFor = (days) =>
  Object.fromEntries(
    Array.from({ length: days }, (_, index) => [
      toISODateFormat(nDaysBefore(new Date(), index * 3)),
      5,
    ]),
  );

describe('initVueInPlacePlayer', () => {
  let wrapper;
  let player;
  let callbacks;
  let onOpen;
  let stopInPlace;

  const findPlayButton = () => wrapper.findByRole('button', { name: 'Play contribution song' });
  const findStopButton = () => wrapper.findByRole('button', { name: 'Stop contribution song' });
  const findOpenButton = () =>
    wrapper.findByRole('button', { name: 'Open contribution song player' });
  const findGrid = () => wrapper.findByTestId('contrib-calendar');
  const findPlayhead = () => findGrid().findByTestId('contribution-music-playhead');
  const findDivider = () => wrapper.findByTestId('contribution-music-divider');
  const findCells = () => findGrid().findAllByTestId('user-contrib-cell');
  // The last day cell; the empty padding cells after it are divs.
  const findToday = () => {
    const cells = findCells();
    let index = cells.length - 1;

    while (cells.at(index).element.tagName !== 'BUTTON') {
      index -= 1;
    }

    return cells.at(index).element;
  };
  const songWeeks = () => player.start.mock.calls[0][0].columns.length;
  // The fade each passed day gets once the song ends: held in its brand color, then back.
  const fadeCallsOn = (cell) =>
    HTMLElement.prototype.animate.mock.calls.filter(
      ([keyframes, options], index) =>
        HTMLElement.prototype.animate.mock.contexts[index] === cell &&
        keyframes[0]?.offset === 0 &&
        options?.delay === BRAND_HOLD_MS &&
        options?.duration === BRAND_FADE_MS,
    );

  const { trigger: triggerResize } = useMockResizeObserver();

  // Like the profile page: the player is set up before the calendar mounts over its element.
  const setUp = async (timestamps = timestampsFor(MIN_ACTIVE_DAYS)) => {
    AjaxCache.retrieve.mockResolvedValue(timestamps);
    setHTMLFixture(`
      <div id="container">
        <div id="js-vue-activity-calendar" data-username="root" data-utc-offset="0"></div>
      </div>
    `);

    stopInPlace = initVueInPlacePlayer({
      container: document.getElementById('container'),
      calendarPath: CALENDAR_PATH,
      utcOffset: 0,
      firstDayOfWeek: 0,
      onOpen,
    });
    initVueActivityCalendar();
    await waitForPromises();
  };

  beforeEach(() => {
    // The calendar and the player's own elements are mounted into the page, not one component.
    wrapper = extendedWrapper(createWrapper(document.body));
    window.gon = { first_day_of_week: 0 };
    onOpen = jest.fn();
    player = { start: jest.fn(), stop: jest.fn() };
    createPlayer.mockImplementation((options) => {
      callbacks = options;
      return player;
    });
    buildWeeks.mockImplementation(actualBuildWeeks);
    glowCell.mockReturnValue({ finished: Promise.resolve(), cancel: jest.fn() });
    HTMLElement.prototype.animate = jest.fn(() => ({
      finished: Promise.resolve(),
      cancel: jest.fn(),
    }));
  });

  afterEach(() => {
    resetHTMLFixture();
    delete HTMLElement.prototype.animate;
  });

  describe('once the calendar has loaded', () => {
    beforeEach(() => setUp());

    it('reads the calendar JSON the calendar does', () => {
      expect(AjaxCache.retrieve).toHaveBeenCalledWith(CALENDAR_PATH);
    });

    it('adds the play button after the legend, set apart by a divider', () => {
      const divider = findPlayButton().element.previousElementSibling;

      expect(divider).toBe(findDivider().element);
      expect(divider.getAttribute('aria-hidden')).toBe('true');
      expect(divider.previousElementSibling.textContent.trim()).toBe('More');
      expect(findPlayButton().attributes('aria-pressed')).toBe('false');
    });

    // Week columns are fractions of the grid's width, which offsetLeft would round.
    describe('with fractional week columns', () => {
      const OFFSET = 30;
      let column;

      beforeEach(() => {
        column = 17.6;
        jest
          .spyOn(HTMLElement.prototype, 'getBoundingClientRect')
          .mockImplementation(function rect() {
            const [, week] = this.id.match(/^calendar-cell-(\d+)-\d+$/) ?? [];
            const left = week === undefined ? 0 : OFFSET + Number(week) * column;

            return { left, top: 0, bottom: 15, right: left + 15, width: 15, height: 15 };
          });

        return findPlayButton().trigger('click');
      });

      it('keeps the playhead on the week that is playing, all year', () => {
        const last = songWeeks() - 1;

        callbacks.onPosition(last / songWeeks());

        expect(parseFloat(findPlayhead().element.style.left)).toBeCloseTo(
          OFFSET + last * column - 1,
        );
      });

      it('measures the columns again when the grid resizes mid-song', () => {
        const last = songWeeks() - 1;

        callbacks.onPosition(last / songWeeks());
        column = 20;
        triggerResize(findGrid().element);

        expect(parseFloat(findPlayhead().element.style.left)).toBeCloseTo(OFFSET + last * 20 - 1);
      });
    });

    describe('when the play button is clicked', () => {
      beforeEach(() => findPlayButton().trigger('click'));

      it('plays a song with one column per week of the calendar, once', () => {
        const weeks = findCells().length / 7;

        expect(player.start).toHaveBeenCalledWith(
          expect.objectContaining({ loop: false, columns: expect.any(Array) }),
        );
        expect(player.start.mock.calls[0][0].columns).toHaveLength(weeks);
      });

      it('turns the button into a stop button', () => {
        expect(findStopButton().attributes('aria-pressed')).toBe('true');
      });

      it('adds a playhead to the grid', () => {
        expect(findPlayhead().element.style.position).toBe('absolute');
      });

      it('glows the days of each week as it plays', () => {
        callbacks.onColumn(songWeeks() - 1);

        expect(glowCell).toHaveBeenCalledWith(findToday(), expect.objectContaining({ level: 1 }));
      });

      describe('and clicked again', () => {
        beforeEach(() => findStopButton().trigger('click'));

        it('stops the song', () => {
          expect(player.stop).toHaveBeenCalled();
          expect(findPlayButton().exists()).toBe(true);
          expect(findPlayhead().exists()).toBe(false);
        });

        // The player starts asynchronously, so it can report in after a quick stop.
        it('ignores the player calling back after the stop', () => {
          expect(() => {
            callbacks.onColumn(0);
            callbacks.onPosition(0.5);
            callbacks.onEnd();
          }).not.toThrow();
          expect(glowCell).not.toHaveBeenCalled();
          expect(findPlayhead().exists()).toBe(false);
          expect(findOpenButton().exists()).toBe(false);
        });
      });

      describe('when the song ends after a week has passed', () => {
        let held;

        beforeEach(async () => {
          callbacks.onColumn(songWeeks() - 1);
          await waitForPromises();

          const { calls, contexts, results } = HTMLElement.prototype.animate.mock;
          const index = calls.findIndex(
            ([, options], i) => contexts[i] === findToday() && options?.fill === 'forwards',
          );

          held = results[index].value;
          callbacks.onEnd();
        });

        it('holds its days in their brand color, then fades them back', () => {
          expect(held.cancel).toHaveBeenCalled();
          expect(fadeCallsOn(findToday())).toHaveLength(1);
        });
      });

      describe('when the song ends while the last weeks still glow', () => {
        let glow;

        beforeEach(() => {
          glow = { finished: new Promise(() => {}), cancel: jest.fn() };
          glowCell.mockReturnValue(glow);
          callbacks.onColumn(songWeeks() - 1);
          callbacks.onEnd();
        });

        it('holds and fades their days too', () => {
          expect(glow.cancel).toHaveBeenCalled();
          expect(fadeCallsOn(findToday())).toHaveLength(1);
        });
      });

      describe('when the song ends', () => {
        beforeEach(() => callbacks.onEnd());

        it('removes the playhead', () => {
          expect(findPlayhead().exists()).toBe(false);
          expect(findPlayButton().exists()).toBe(true);
        });

        it('offers to open the full player', async () => {
          await findOpenButton().trigger('click');

          expect(onOpen).toHaveBeenCalled();
        });
      });

      it('stops the song when the full player opens', () => {
        stopInPlace();

        expect(player.stop).toHaveBeenCalled();
        expect(findPlayButton().exists()).toBe(true);
      });
    });
  });

  describe('with too few active days for a song', () => {
    beforeEach(() => setUp(timestampsFor(MIN_ACTIVE_DAYS - 1)));

    it('adds no play button', () => {
      expect(findPlayButton().exists()).toBe(false);
    });
  });

  // The cells are matched to the data by position, so a mismatch would glow the wrong days.
  describe('when the calendar has a different number of weeks than the data', () => {
    beforeEach(() => {
      buildWeeks.mockImplementation((options) => {
        const weeks = actualBuildWeeks(options);

        return [...weeks, weeks.at(-1)];
      });

      return setUp();
    });

    it('adds no play button or divider', () => {
      expect(findGrid().exists()).toBe(true);
      expect(findPlayButton().exists()).toBe(false);
      expect(findDivider().exists()).toBe(false);
    });
  });

  describe('when the calendar fails to load', () => {
    const findRetryButton = () =>
      [...document.querySelectorAll('button')].find(
        (button) => button.textContent.trim() === 'Retry',
      );

    beforeEach(async () => {
      AjaxCache.retrieve.mockRejectedValue(new Error('500'));
      setHTMLFixture(`
        <div id="container">
          <div id="js-vue-activity-calendar" data-username="root" data-utc-offset="0"></div>
        </div>
      `);
      initVueInPlacePlayer({
        container: document.getElementById('container'),
        calendarPath: CALENDAR_PATH,
        utcOffset: 0,
        firstDayOfWeek: 0,
        onOpen,
      });
      initVueActivityCalendar();
      await waitForPromises();
    });

    it('adds no play button', () => {
      expect(findPlayButton().exists()).toBe(false);
    });

    describe('and the retry succeeds', () => {
      beforeEach(async () => {
        AjaxCache.retrieve.mockResolvedValue(timestampsFor(MIN_ACTIVE_DAYS));
        findRetryButton().click();
        await waitForPromises();
      });

      it('adds the play button', () => {
        expect(findPlayButton().exists()).toBe(true);
      });
    });
  });
});
