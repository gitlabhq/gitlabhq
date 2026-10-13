import { GlAlert, GlLink, GlEmptyState, GlButton, GlSprintf } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ActivityCalendar from '~/profile/components/activity_calendar.vue';
import ActivitySkeletonLoader from '~/profile/components/activity_skeleton_loader.vue';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import AjaxCache from '~/lib/utils/ajax_cache';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/ajax_cache');

const ACTIVITY_PATH = '/users/root/activity.json';
const CALENDAR_ACTIVITIES_PATH = '/users/root/calendar_activities';

describe('ActivityCalendar', () => {
  let wrapper;
  let mock;

  // August 5th, 2026 (Wednesday)
  useFakeDate(2026, 7, 5);

  const defaultProvide = {
    username: 'root',
    utcOffset: 0,
    userCalendarActivitiesPath: CALENDAR_ACTIVITIES_PATH,
    userActivityPath: ACTIVITY_PATH,
    viewAllActivityPath: '/users/root/activity',
    isCurrentUserProfile: false,
    emptyStateSvgPath: '/illustrations/empty-activity.svg',
    newGroupPath: '/groups/new',
    exploreGroupsPath: '/explore/groups',
  };

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(ActivityCalendar, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const expectToBeEmptyCells = (...cells) => {
    cells.forEach((cell) => {
      expect(cell.attributes('aria-hidden')).toBe('true');
      // Padding cells are plain divs so they are not focusable, and carry no
      // label of their own.
      expect(cell.element.tagName).toBe('DIV');
      expect(cell.attributes('aria-label')).toBeUndefined();
    });
  };

  // Asserts the boundary between padding and real days, so the tests above fail
  // if the padding grows rather than only if it shrinks.
  const expectToBeDateCells = (...cells) => {
    cells.forEach((cell) => {
      expect(cell.attributes('aria-hidden')).toBeUndefined();
      // Real days render as buttons so they can be focused and activated.
      expect(cell.element.tagName).toBe('BUTTON');
    });
  };

  const findCalendar = () => wrapper.findByTestId('contrib-calendar');
  const findCells = () => wrapper.findAllByTestId('user-contrib-cell');
  const findDateCells = () =>
    findCells().wrappers.filter((cell) => cell.attributes('aria-hidden') !== 'true');
  const findMonthLabels = () => wrapper.findAllByTestId('month-label');
  const findDayLabels = () => wrapper.findAllByTestId('day-label');
  const findRenderedMonthLabels = () =>
    findMonthLabels().wrappers.filter((label) => label.text() !== '');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const getCellTooltip = (cell) => getBinding(cell.element, 'gl-tooltip').value;

  beforeEach(() => {
    gon.first_day_of_week = 0;
    AjaxCache.retrieve.mockResolvedValue({});

    mock = new MockAdapter(axios);
    // The general feed auto-loads on mount; the day feed loads on cell click.
    mock.onGet(ACTIVITY_PATH).reply(200, []);
    mock.onGet(CALENDAR_ACTIVITIES_PATH).reply(200, []);
  });

  afterEach(async () => {
    // Flush the auto-loaded activity feed request before restoring the mock so
    // synchronous render-only tests do not leak a pending request into teardown.
    await waitForPromises();
    delete gon.first_day_of_week;
    mock.restore();
  });

  describe('skeleton grid', () => {
    it('renders the activity heading', () => {
      createComponent();

      expect(wrapper.find('h2').text()).toBe('Activity');
    });

    it('renders the calendar as an accessible group', () => {
      createComponent();

      expect(findCalendar().attributes('role')).toBe('group');
      expect(findCalendar().attributes('aria-label')).toBe('Contribution activity calendar');
    });

    it('renders 53 week columns for a midweek date (Wednesday, August 5th, 2026)', () => {
      createComponent();

      // 53 weeks * 7 days
      expect(findCells()).toHaveLength(371);
    });

    it('renders a date cell for every day in the last 12 months, each at level 0', () => {
      createComponent();

      const dateCells = findDateCells();

      // 12 months inclusive of both endpoints, so 366 days (367 across a leap day)
      expect(dateCells).toHaveLength(366);
      dateCells.forEach((cell) => {
        expect(cell.classes()).toContain('user-contribution-graph-cell-0');
      });
    });

    it('pads the grid so cells always form full week columns', () => {
      createComponent();

      const cells = findCells().wrappers;
      const [firstCell, secondCell, thirdCell] = cells;
      const [fourthToLastCell, thirdToLastCell, secondToLastCell, lastCell] = cells.slice(-4);

      expectToBeEmptyCells(firstCell, secondCell, lastCell, secondToLastCell, thirdToLastCell);
      expectToBeDateCells(thirdCell, fourthToLastCell);
    });

    describe('when the range starts on the last day of the week', () => {
      // August 9th, 2026 (Sunday). The range starts on Saturday August 9th, 2025,
      // the last day of the week, so six empty cells precede it and the grid
      // spills into a 54th column.
      useFakeDate(2026, 7, 9);

      it('renders 54 week columns', () => {
        createComponent();

        // 54 weeks * 7 days
        expect(findCells()).toHaveLength(378);
      });

      it('still renders a date cell for every day in the last 12 months', () => {
        createComponent();

        expect(findDateCells()).toHaveLength(366);
      });

      it('pads both ends with six empty cells', () => {
        createComponent();

        const cells = findCells().wrappers;
        const leading = cells.slice(0, 6);
        const trailing = cells.slice(-6);

        expectToBeEmptyCells(...leading, ...trailing);
        expectToBeDateCells(cells[6], cells.at(-7));
      });
    });

    describe('when day of the week changes (Wednesday -> Thursday)', () => {
      // August 6th, 2026 (Thursday)
      useFakeDate(2026, 7, 6);

      it('shifts the grid padding', () => {
        createComponent();

        const cells = findCells().wrappers;
        const [firstCell, secondCell, thirdCell, fourthCell] = cells;
        const [thirdToLastCell, secondToLastCell, lastCell] = cells.slice(-3);

        expectToBeEmptyCells(firstCell, secondCell, thirdCell, lastCell, secondToLastCell);
        expectToBeDateCells(fourthCell, thirdToLastCell);
      });
    });

    describe('when first_day_of_week is Monday', () => {
      beforeEach(() => {
        gon.first_day_of_week = 1;
        createComponent();
      });

      it('shifts the grid padding', () => {
        const cells = findCells().wrappers;
        const [firstCell, secondCell] = cells;
        const [fifthToLastCell, fourthToLastCell, thirdToLastCell, secondToLastCell, lastCell] =
          cells.slice(-5);

        expectToBeEmptyCells(
          firstCell,
          lastCell,
          secondToLastCell,
          thirdToLastCell,
          fourthToLastCell,
        );
        expectToBeDateCells(secondCell, fifthToLastCell);
      });
    });

    describe('when utcOffset is behind UTC', () => {
      // August 9th, 2026 (Sunday) at 00:00 UTC, which renders 54 columns at UTC.
      useFakeDate(2026, 7, 9);

      beforeEach(() => {
        createComponent({ utcOffset: -25200 }); // UTC-7
      });

      it('resolves the system date to the previous day', () => {
        // Saturday August 8th, so the range starts on Friday and only 53 columns
        // are needed. 53 weeks * 7 days.
        expect(findCells()).toHaveLength(371);
      });

      it('shifts the grid padding', () => {
        const cells = findCells().wrappers;
        const [firstCell, secondCell, thirdCell, fourthCell, fifthCell, sixthCell] = cells;
        const lastCell = cells.at(-1);

        expectToBeEmptyCells(firstCell, secondCell, thirdCell, fourthCell, fifthCell);
        expectToBeDateCells(sixthCell, lastCell);
      });
    });
  });

  describe('month labels', () => {
    it('renders one label slot per week, with a visible label per month boundary', () => {
      createComponent();

      // The frozen 12-month range (Aug 5th, 2025 - Aug 5th, 2026) renders 53
      // weeks and crosses 13 month boundaries, including both partial Augusts.
      expect(findMonthLabels()).toHaveLength(53);
      expect(findRenderedMonthLabels()).toHaveLength(13);
    });

    it('hides only the empty label slots from assistive technology', () => {
      createComponent();

      findMonthLabels().wrappers.forEach((label) => {
        expect(label.attributes('role')).toBe('presentation');

        if (label.text() === '') {
          expect(label.attributes('aria-hidden')).toBe('true');
        } else {
          expect(label.attributes('aria-hidden')).toBeUndefined();
        }
      });
    });

    describe('when the first week is the last week of the month', () => {
      // July 28th, 2026: the range starts on Monday July 28th, 2025, in the
      // last week of July, so the second week already belongs to August.
      useFakeDate(2026, 6, 28);

      it('skips the label of the first week so it cannot overlap the next one', () => {
        createComponent();

        expect(findMonthLabels().at(0).text()).toBe('');
        expect(findMonthLabels().at(1).text()).toBe('Aug');
      });
    });

    describe('when the first week is the second to last week of the month', () => {
      // July 21st, 2026: the range starts on Monday July 21st, 2025 and the
      // second week still starts in July.
      useFakeDate(2026, 6, 21);

      it('renders the label on the first week', () => {
        createComponent();

        expect(findMonthLabels().at(0).text()).toBe('Jul');
        expect(findMonthLabels().at(1).text()).toBe('');
        expect(findMonthLabels().at(2).text()).toBe('Aug');
      });
    });

    describe('when the first week is the first week of the month', () => {
      // August 4th, 2026: the range starts on Monday August 4th, 2025.
      useFakeDate(2026, 7, 4);

      it('renders the label on the first week', () => {
        createComponent();

        expect(findMonthLabels().at(0).text()).toBe('Aug');
        expect(findMonthLabels().at(1).text()).toBe('');
      });
    });

    describe('when the first week is the second week of the month', () => {
      // August 11th, 2026: the range starts on Monday August 11th, 2025.
      useFakeDate(2026, 7, 11);

      it('renders the label on the first week', () => {
        createComponent();

        expect(findMonthLabels().at(0).text()).toBe('Aug');
        expect(findMonthLabels().at(1).text()).toBe('');
      });
    });
  });

  describe('day labels', () => {
    it.each`
      firstDayOfWeek | description   | expectedLabels
      ${0}           | ${'Sunday'}   | ${['', 'M', '', 'W', '', 'F', '']}
      ${1}           | ${'Monday'}   | ${['M', '', 'W', '', 'F', '', 'S']}
      ${6}           | ${'Saturday'} | ${['S', '', 'M', '', 'W', '', 'F']}
    `(
      'renders $expectedLabels when the week starts on $description',
      ({ firstDayOfWeek, expectedLabels }) => {
        gon.first_day_of_week = firstDayOfWeek;
        createComponent();

        expect(findDayLabels().wrappers.map((label) => label.text())).toEqual(expectedLabels);
      },
    );

    it('hides only the empty label slots from assistive technology', () => {
      createComponent();

      findDayLabels().wrappers.forEach((label) => {
        expect(label.attributes('role')).toBe('presentation');

        if (label.text() === '') {
          expect(label.attributes('aria-hidden')).toBe('true');
        } else {
          expect(label.attributes('aria-hidden')).toBeUndefined();
        }
      });
    });
  });

  describe('fetching contributions', () => {
    it('requests the calendar data using the user calendar path helper', async () => {
      createComponent();
      await waitForPromises();

      expect(AjaxCache.retrieve).toHaveBeenCalledWith('/users/root/calendar.json');
    });

    it('marks the calendar as busy while loading and not busy once loaded', async () => {
      createComponent();
      expect(findCalendar().attributes('aria-busy')).toBe('true');

      await waitForPromises();
      expect(findCalendar().attributes('aria-busy')).not.toBe('true');
    });
  });

  describe('displaying contributions', () => {
    // Today's date is stubbed to 2026-08-05 at top of spec
    describe.each`
      contributionCount | date            | expectedCellIndex | expectedLevel | expectedAriaLabel                                | expectedTooltip
      ${0}              | ${'2025-08-05'} | ${2}              | ${0}          | ${'No contributions on Tuesday, August 5, 2025'} | ${'No contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${1}              | ${'2025-08-05'} | ${2}              | ${1}          | ${'1 contribution on Tuesday, August 5, 2025'}   | ${'1 contribution<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${9}              | ${'2025-08-05'} | ${2}              | ${1}          | ${'9 contributions on Tuesday, August 5, 2025'}  | ${'9 contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${10}             | ${'2025-08-05'} | ${2}              | ${2}          | ${'10 contributions on Tuesday, August 5, 2025'} | ${'10 contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${19}             | ${'2025-08-05'} | ${2}              | ${2}          | ${'19 contributions on Tuesday, August 5, 2025'} | ${'19 contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${20}             | ${'2025-08-05'} | ${2}              | ${3}          | ${'20 contributions on Tuesday, August 5, 2025'} | ${'20 contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${29}             | ${'2025-08-05'} | ${2}              | ${3}          | ${'29 contributions on Tuesday, August 5, 2025'} | ${'29 contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${30}             | ${'2025-08-05'} | ${2}              | ${4}          | ${'30 contributions on Tuesday, August 5, 2025'} | ${'30 contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
      ${39}             | ${'2025-08-05'} | ${2}              | ${4}          | ${'39 contributions on Tuesday, August 5, 2025'} | ${'39 contributions<br /><span class="gl-text-neutral-300">Tuesday, August 5, 2025</span>'}
    `(
      'when contribution count is $contributionCount and date is $date',
      ({
        contributionCount,
        date,
        expectedCellIndex,
        expectedLevel,
        expectedAriaLabel,
        expectedTooltip,
      }) => {
        beforeEach(async () => {
          AjaxCache.retrieve.mockResolvedValue({ [date]: contributionCount });
          createComponent();
          await waitForPromises();
        });

        it(`renders cell with expected level of ${expectedLevel}`, () => {
          expect(findCells().at(expectedCellIndex).classes()).toContain(
            `user-contribution-graph-cell-${expectedLevel}`,
          );
        });

        it(`renders cell with expected aria-label of ${expectedAriaLabel}`, () => {
          expect(findCells().at(expectedCellIndex).attributes('aria-label')).toBe(
            expectedAriaLabel,
          );
        });

        it(`renders cell with expected tooltip of ${expectedTooltip}`, () => {
          expect(getCellTooltip(findCells().at(expectedCellIndex))).toBe(expectedTooltip);
        });
      },
    );
  });

  describe('legend', () => {
    it.each`
      index | level | title
      ${0}  | ${0}  | ${'No contributions'}
      ${1}  | ${1}  | ${'1-9 contributions'}
      ${2}  | ${2}  | ${'10-19 contributions'}
      ${3}  | ${3}  | ${'20-29 contributions'}
      ${4}  | ${4}  | ${'30+ contributions'}
    `('renders the level $level swatch with the $title tooltip', ({ index, level, title }) => {
      createComponent();

      const swatches = wrapper.findAllByTestId('legend-cell');
      expect(swatches).toHaveLength(5);

      const swatch = swatches.at(index);
      expect(swatch.classes()).toContain(`user-contribution-graph-cell-${level}`);
      expect(getCellTooltip(swatch)).toBe(title);
      expect(swatch.attributes('aria-label')).toBe(title);
    });
  });

  describe('error handling', () => {
    it('shows a retry alert when the request fails', async () => {
      AjaxCache.retrieve.mockRejectedValue(new Error('boom'));
      createComponent();
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('primaryButtonText')).toBe('Retry');
    });

    it('retries fetching when the alert primary action is triggered', async () => {
      AjaxCache.retrieve.mockRejectedValueOnce(new Error('boom')).mockResolvedValueOnce({});
      createComponent();
      await waitForPromises();

      findAlert().vm.$emit('primary-action');
      await waitForPromises();

      expect(findAlert().exists()).toBe(false);
      expect(AjaxCache.retrieve).toHaveBeenCalledTimes(2);
    });
  });

  describe('keyboard navigation', () => {
    // The focused cell is observable as the single cell with tabindex="0" (the
    // accessible tab-stop). Because each cell binds handleKeyDown with its own
    // coordinates, pressing a key on a specific cell navigates relative to it,
    // so tests drive setup with real key presses rather than internal state.
    const findCellById = (weekIndex, dayIndex) =>
      wrapper.find(`#calendar-cell-${weekIndex}-${dayIndex}`);

    const findTabbableCell = () =>
      findCells().wrappers.find((cell) => cell.attributes('tabindex') === '0');

    const tabbableCellId = () => findTabbableCell().attributes('id');

    const pressKeyOn = (weekIndex, dayIndex, key) =>
      findCellById(weekIndex, dayIndex).trigger('keydown', { key });

    // The first real (non-padding) cell in DOM order, which is where the
    // initial tab-stop sits. Its exact coordinates depend on the mocked date's
    // first-week padding, so tests derive it rather than hardcoding it.
    const findFirstDateCell = () =>
      findCells().wrappers.find((cell) => cell.element.tagName === 'BUTTON');

    beforeEach(async () => {
      AjaxCache.retrieve.mockResolvedValue({});
      createComponent();
      await waitForPromises();
    });

    describe('roving tabindex', () => {
      it('makes exactly one cell tabbable', () => {
        const tabbableCells = findCells().wrappers.filter(
          (cell) => cell.attributes('tabindex') === '0',
        );

        expect(tabbableCells).toHaveLength(1);
      });

      it('makes the first non-empty cell tabbable', () => {
        expect(tabbableCellId()).toBe(findFirstDateCell().attributes('id'));
        expect(findTabbableCell().element.tagName).toBe('BUTTON');
      });

      it('renders all other cells as not tabbable', () => {
        const notTabbable = findCells().wrappers.filter(
          (cell) => cell.attributes('tabindex') === '-1',
        );

        expect(notTabbable).toHaveLength(findCells().length - 1);
      });

      it('makes a real day cell tabbable before the fetch resolves', () => {
        AjaxCache.retrieve.mockReturnValue(new Promise(() => {}));
        createComponent();

        expect(findTabbableCell().element.tagName).toBe('BUTTON');
      });

      it('moves the tab-stop to the cell the user navigates to', async () => {
        // Day 2 is the first non-padding row under the default mocked date.
        await pressKeyOn(0, 2, 'ArrowRight');

        expect(tabbableCellId()).toBe('calendar-cell-1-2');
      });
    });

    describe('arrow keys', () => {
      it('ArrowRight moves focus to the next week (same day row)', async () => {
        // Day 2 is the first non-padding row under the default mocked date.
        await pressKeyOn(0, 2, 'ArrowRight');

        expect(tabbableCellId()).toBe('calendar-cell-1-2');
      });

      it('ArrowLeft moves focus to the previous week (same day row)', async () => {
        await pressKeyOn(1, 2, 'ArrowLeft');

        expect(tabbableCellId()).toBe('calendar-cell-0-2');
      });

      it('ArrowDown moves focus to the next day (same week column)', async () => {
        await pressKeyOn(5, 2, 'ArrowDown');

        expect(tabbableCellId()).toBe('calendar-cell-5-3');
      });

      it('ArrowUp from the top day of a week wraps to the previous week', async () => {
        await pressKeyOn(1, 0, 'ArrowUp');

        expect(tabbableCellId()).toBe('calendar-cell-0-6');
      });
    });

    describe('Home and End keys', () => {
      it('Home moves focus to the first day of the current week', async () => {
        await pressKeyOn(5, 4, 'Home');

        expect(tabbableCellId()).toBe('calendar-cell-5-0');
      });

      it('End moves focus to the last day of the current week', async () => {
        await pressKeyOn(5, 1, 'End');

        expect(tabbableCellId()).toBe('calendar-cell-5-6');
      });
    });

    describe('PageUp and PageDown keys', () => {
      it('PageDown moves focus four weeks forward', async () => {
        await pressKeyOn(2, 3, 'PageDown');

        expect(tabbableCellId()).toBe('calendar-cell-6-3');
      });

      it('PageUp moves focus four weeks backward', async () => {
        await pressKeyOn(6, 3, 'PageUp');

        expect(tabbableCellId()).toBe('calendar-cell-2-3');
      });
    });

    describe('padded edges (disabled cells)', () => {
      // Fixed date so the padding of the first and last weeks is
      // deterministic: the range runs Feb 21 2022 - Feb 21 2023, giving the
      // first week one leading empty cell (day 0) and the last week (index
      // 52) four trailing empty cells (days 3-6).
      useFakeDate(2023, 1, 21);

      it('ArrowRight from the last week wraps to the start of the next row', async () => {
        await pressKeyOn(52, 1, 'ArrowRight');

        // Day 2 row starts at week 0 (only day 0 of the first week is padding).
        expect(tabbableCellId()).toBe('calendar-cell-0-2');
      });

      it('ArrowLeft from the first week wraps to the end of the previous row', async () => {
        await pressKeyOn(0, 3, 'ArrowLeft');

        expect(tabbableCellId()).toBe('calendar-cell-52-2');
      });

      it('ArrowLeft skips the disabled cells of the last week when wrapping to the previous row', async () => {
        await pressKeyOn(0, 4, 'ArrowLeft');

        // Day 3 of the last week is padding, so focus lands on the week before.
        expect(tabbableCellId()).toBe('calendar-cell-51-3');
      });

      it('ArrowRight skips the disabled cells of the last week and wraps to the next row', async () => {
        await pressKeyOn(51, 5, 'ArrowRight');

        expect(tabbableCellId()).toBe('calendar-cell-0-6');
      });

      it('ArrowDown from the last available cell wraps to the first available cell', async () => {
        await pressKeyOn(52, 2, 'ArrowDown');

        expect(tabbableCellId()).toBe('calendar-cell-0-1');
      });

      it('ArrowUp from the first available cell wraps to the last available cell', async () => {
        await pressKeyOn(0, 1, 'ArrowUp');

        expect(tabbableCellId()).toBe('calendar-cell-52-2');
      });

      it('Home moves to the first available day in the padded first week', async () => {
        await pressKeyOn(0, 4, 'Home');

        expect(tabbableCellId()).toBe('calendar-cell-0-1');
      });

      it('End moves to the last available day in the padded last week', async () => {
        await pressKeyOn(52, 1, 'End');

        expect(tabbableCellId()).toBe('calendar-cell-52-2');
      });

      it('PageDown near the end clamps to the last week instead of wrapping', async () => {
        await pressKeyOn(50, 1, 'PageDown');

        expect(tabbableCellId()).toBe('calendar-cell-52-1');
      });

      it('PageDown clamping backs off the padding cells of the last week', async () => {
        await pressKeyOn(50, 4, 'PageDown');

        // Day 4 of the last week is padding, so focus lands on the week before.
        expect(tabbableCellId()).toBe('calendar-cell-51-4');
      });

      it('PageUp near the start clamps to the first week instead of wrapping', async () => {
        await pressKeyOn(2, 3, 'PageUp');

        expect(tabbableCellId()).toBe('calendar-cell-0-3');
      });

      it('PageUp clamping backs off the padding cell of the first week', async () => {
        await pressKeyOn(3, 0, 'PageUp');

        // Day 0 of the first week is padding, so focus lands on the week after.
        expect(tabbableCellId()).toBe('calendar-cell-1-0');
      });
    });

    describe('event handling', () => {
      const dispatchKeydown = (weekIndex, dayIndex, key) => {
        const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
        findCellById(weekIndex, dayIndex).element.dispatchEvent(event);

        return event;
      };

      it('prevents default scrolling for handled navigation keys', () => {
        // Day 2 is the first non-padding cell under the default mocked date.
        const event = dispatchKeydown(0, 2, 'ArrowRight');

        expect(event.defaultPrevented).toBe(true);
      });

      it('does not prevent default for unhandled keys', () => {
        const event = dispatchKeydown(0, 2, 'Enter');

        expect(event.defaultPrevented).toBe(false);
      });
    });
  });

  describe('activity feed', () => {
    const findViewAllLink = () => wrapper.findComponent(GlLink);
    const findActivities = () => wrapper.findByTestId('calendar-activities');
    const findEmptyState = () => wrapper.findComponent(GlEmptyState);
    const findSkeleton = () => wrapper.findComponent(ActivitySkeletonLoader);
    const findEvents = () => wrapper.findComponent(ContributionEvents);
    const findLoadMore = () => findActivities().findComponent(GlButton);
    const firstDateCell = () => findDateCells()[0];
    const findTabbableCell = () =>
      findCells().wrappers.find((cell) => cell.attributes('tabindex') === '0');

    describe('View all link', () => {
      it('links to the activity page', async () => {
        createComponent();
        await waitForPromises();

        expect(findViewAllLink().attributes('href')).toBe('/users/root/activity');
        expect(findViewAllLink().text()).toBe('View all');
      });

      it('is hidden when the user has no activity', async () => {
        createComponent();
        await waitForPromises();

        expect(findViewAllLink().classes()).toContain('gl-hidden');
      });

      it('is shown when the user has activity', async () => {
        mock.onGet(ACTIVITY_PATH).reply(200, [{ id: 1 }]);

        createComponent();
        await waitForPromises();

        expect(findViewAllLink().classes()).not.toContain('gl-hidden');
      });

      it('stays visible based on overall activity, not the selected day', async () => {
        mock.onGet(ACTIVITY_PATH).reply(200, [{ id: 1 }]);
        mock.onGet(CALENDAR_ACTIVITIES_PATH).reply(200, []);

        createComponent();
        await waitForPromises();

        await firstDateCell().trigger('click');
        await waitForPromises();

        expect(findViewAllLink().classes()).not.toContain('gl-hidden');
      });
    });

    describe('loading state', () => {
      it('renders the skeleton loader while the feed is loading', async () => {
        mock.onGet(ACTIVITY_PATH).reply(() => new Promise(() => {}));

        createComponent();
        await waitForPromises();

        expect(findSkeleton().exists()).toBe(true);
      });
    });

    describe('when the general feed returns events', () => {
      beforeEach(async () => {
        mock.onGet(ACTIVITY_PATH).reply(200, [{ id: 1 }, { id: 2 }]);

        createComponent();
        await waitForPromises();
      });

      it('renders the events feed', () => {
        expect(findEvents().props('events')).toHaveLength(2);
      });

      it('does not render the empty state', () => {
        expect(findEmptyState().exists()).toBe(false);
      });
    });

    describe('day selection', () => {
      beforeEach(async () => {
        mock.onGet(ACTIVITY_PATH).reply(200, [{ id: 1 }]);
        createComponent();
        await waitForPromises();
      });

      it('requests the selected day activities on cell click', async () => {
        await firstDateCell().trigger('click');
        await waitForPromises();

        const dayRequest = mock.history.get.find((req) => req.url === CALENDAR_ACTIVITIES_PATH);

        expect(dayRequest.params).toMatchObject({ limit: 50, offset: 0 });
        expect(dayRequest.params.date).toEqual(expect.any(String));
      });

      it('renders the selected day heading', async () => {
        await firstDateCell().trigger('click');
        await waitForPromises();

        // GlSprintf is a functional stub under shallowMount, so assert on the
        // message it receives via its attributes.
        expect(findActivities().findComponent(GlSprintf).attributes('message')).toContain(
          'Contributions for',
        );
      });

      it('marks the clicked cell as active', async () => {
        const cell = firstDateCell();
        await cell.trigger('click');
        await waitForPromises();

        expect(cell.classes()).toContain('is-active');
      });

      it('moves the roving tab-stop to the active cell so tabbing returns to it', async () => {
        const cell = firstDateCell();
        await cell.trigger('click');
        await waitForPromises();

        // The active cell is the single tabbable cell, so Tab lands on it.
        expect(cell.attributes('tabindex')).toBe('0');
        expect(cell.attributes('id')).toBe(findTabbableCell().attributes('id'));
      });

      it('deselects the day when the active cell is clicked again', async () => {
        const cell = firstDateCell();
        await cell.trigger('click');
        await waitForPromises();

        await cell.trigger('click');
        await waitForPromises();

        expect(cell.classes()).not.toContain('is-active');
      });

      it('shows the no contributions message when the day has none', async () => {
        mock.onGet(CALENDAR_ACTIVITIES_PATH).reply(200, []);

        await firstDateCell().trigger('click');
        await waitForPromises();

        expect(wrapper.findByText('No contributions were found.').exists()).toBe(true);
      });
    });

    describe('load more', () => {
      beforeEach(async () => {
        // A full page signals more pages are available.
        mock.onGet(ACTIVITY_PATH).reply(200, new Array(15).fill({ id: 1 }));
        createComponent();
        await waitForPromises();
      });

      it('renders a load more button when more activities are available', () => {
        expect(findLoadMore().exists()).toBe(true);
      });

      it('requests the next page when clicked', async () => {
        await findLoadMore().vm.$emit('click');
        await waitForPromises();

        const generalRequests = mock.history.get.filter((req) => req.url === ACTIVITY_PATH);

        expect(generalRequests).toHaveLength(2);
        expect(generalRequests[1].params).toMatchObject({ offset: 15, limit: 50 });
      });
    });

    describe('error state', () => {
      it('shows a retry alert when the feed request fails', async () => {
        mock.onGet(ACTIVITY_PATH).reply(500);

        createComponent();
        await waitForPromises();

        expect(findActivities().findComponent(GlAlert).props('title')).toBe(
          'There was an error loading activities.',
        );
      });
    });

    describe('empty state', () => {
      it("renders a call to action on the current user's own profile", async () => {
        createComponent({ isCurrentUserProfile: true });
        await waitForPromises();

        expect(findEmptyState().props()).toMatchObject({
          title: 'No activities found',
          svgPath: '/illustrations/empty-activity.svg',
          primaryButtonText: 'New group',
          primaryButtonLink: '/groups/new',
          secondaryButtonText: 'Explore groups',
          secondaryButtonLink: '/explore/groups',
        });
      });

      it("omits the call to action on another user's profile", async () => {
        createComponent({ isCurrentUserProfile: false });
        await waitForPromises();

        expect(findEmptyState().props('title')).toBe('No activities found');
        expect(findEmptyState().props('primaryButtonText')).toBe(null);
        expect(findEmptyState().props('secondaryButtonText')).toBe(null);
      });
    });

    describe('when the feed is disabled (no activity path)', () => {
      beforeEach(async () => {
        createComponent({ userActivityPath: null });
        await waitForPromises();
      });

      it('renders the calendar without the activities section', () => {
        expect(findCalendar().exists()).toBe(true);
        expect(findActivities().exists()).toBe(false);
      });

      it('does not render the View all link', () => {
        expect(findViewAllLink().exists()).toBe(false);
      });

      it('does not request the activity feed', () => {
        expect(mock.history.get.some((req) => req.url === ACTIVITY_PATH)).toBe(false);
      });
    });
  });
});
