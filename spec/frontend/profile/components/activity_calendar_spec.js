import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivityCalendar from '~/profile/components/activity_calendar.vue';
import { useFakeDate } from 'helpers/fake_date';

describe('ActivityCalendar', () => {
  let wrapper;

  // August 5th, 2026 (Wednesday)
  useFakeDate(2026, 7, 5);

  const defaultProvide = {
    utcOffset: 0,
  };

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(ActivityCalendar, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const expectToBeEmptyCells = (...cells) => {
    cells.forEach((cell) => {
      expect(cell.attributes('aria-hidden')).toBe('true');
    });
  };

  // Asserts the boundary between padding and real days, so the tests above fail
  // if the padding grows rather than only if it shrinks.
  const expectToBeDateCells = (...cells) => {
    cells.forEach((cell) => {
      expect(cell.attributes('aria-hidden')).toBeUndefined();
    });
  };

  const findCalendar = () => wrapper.findByTestId('contrib-calendar');
  const findCells = () => wrapper.findAllByTestId('user-contrib-cell');
  const findDateCells = () =>
    findCells().wrappers.filter((cell) => cell.attributes('aria-hidden') !== 'true');

  beforeEach(() => {
    gon.first_day_of_week = 0;
  });

  afterEach(() => {
    delete gon.first_day_of_week;
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
});
