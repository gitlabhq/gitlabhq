import { scaleTablesForPrint, resetScrollForPrint } from '~/wikis/utils/print_table_scale';

/**
 * jsdom does not implement layout, so clientWidth and scrollWidth are always 0.
 * We mock them via Object.defineProperty to simulate wide-table scenarios.
 */
function mockDimensions(el, { clientWidth, scrollWidth }) {
  Object.defineProperty(el, 'clientWidth', { configurable: true, get: () => clientWidth });
  Object.defineProperty(el, 'scrollWidth', { configurable: true, get: () => scrollWidth });
}

describe('scaleTablesForPrint', () => {
  let root;
  let table;

  const scaleOf = (el) => el.style.getPropertyValue('--print-table-scale');

  beforeEach(() => {
    root = document.createElement('div');
    document.body.appendChild(root);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  // A table inside a scrollable wrapper: the wrapper carries
  // data-print-scale-container, the table carries data-print-scale-target.  The
  // wrapper is what clips, so only its clientWidth reports the visible width;
  // the table lays out at its full width inside it.
  const createWrappedTable = ({ containerWidth, tableWidth }) => {
    const container = document.createElement('div');
    container.dataset.printScaleContainer = '';
    const wrapped = document.createElement('table');
    wrapped.dataset.printScaleTarget = '';
    container.appendChild(wrapped);
    root.appendChild(container);
    mockDimensions(container, { clientWidth: containerWidth, scrollWidth: containerWidth });
    mockDimensions(wrapped, { clientWidth: tableWidth, scrollWidth: tableWidth });
    return wrapped;
  };

  // A regular table is its own container, so it carries both attributes.
  const createRegularTable = ({ clientWidth, scrollWidth }) => {
    const regular = document.createElement('table');
    regular.dataset.printScaleContainer = '';
    regular.dataset.printScaleTarget = '';
    root.appendChild(regular);
    mockDimensions(regular, { clientWidth, scrollWidth });
    return regular;
  };

  describe('with a table inside a scale container', () => {
    describe('when the table is wider than its container', () => {
      beforeEach(() => {
        table = createWrappedTable({ containerWidth: 500, tableWidth: 1000 });

        scaleTablesForPrint(root);
      });

      it('records the ratio of container width to table width', () => {
        expect(scaleOf(table)).toBe('0.5');
      });

      it('leaves the zoom to the print stylesheet', () => {
        expect(table.style.zoom).toBeUndefined();
      });
    });

    describe('when the table already carries a scale from an earlier print', () => {
      beforeEach(() => {
        table = createWrappedTable({ containerWidth: 500, tableWidth: 1000 });
        table.style.setProperty('--print-table-scale', '0.8');

        scaleTablesForPrint(root);
      });

      it('replaces it with the re-measured scale', () => {
        expect(scaleOf(table)).toBe('0.5');
      });
    });

    describe('when the table fits within its container', () => {
      beforeEach(() => {
        table = createWrappedTable({ containerWidth: 500, tableWidth: 400 });

        scaleTablesForPrint(root);
      });

      it('records no scale', () => {
        expect(scaleOf(table)).toBe('');
      });
    });

    describe('when the table has grown to fit since the last print', () => {
      beforeEach(() => {
        table = createWrappedTable({ containerWidth: 500, tableWidth: 400 });
        table.style.setProperty('--print-table-scale', '0.5');

        scaleTablesForPrint(root);
      });

      it('clears the stale scale', () => {
        expect(scaleOf(table)).toBe('');
      });
    });

    describe('when the container has no measurable width', () => {
      beforeEach(() => {
        table = createWrappedTable({ containerWidth: 0, tableWidth: 500 });

        scaleTablesForPrint(root);
      });

      it('records no scale', () => {
        expect(scaleOf(table)).toBe('');
      });
    });
  });

  describe('with a regular table that is its own scale container', () => {
    describe('when the table overflows itself', () => {
      beforeEach(() => {
        table = createRegularTable({ clientWidth: 400, scrollWidth: 800 });

        scaleTablesForPrint(root);
      });

      it('records the ratio of visible width to content width', () => {
        expect(scaleOf(table)).toBe('0.5');
      });
    });

    describe('when the table fits', () => {
      beforeEach(() => {
        table = createRegularTable({ clientWidth: 400, scrollWidth: 400 });

        scaleTablesForPrint(root);
      });

      it('records no scale', () => {
        expect(scaleOf(table)).toBe('');
      });
    });
  });

  describe('with a table that is not a scale target', () => {
    beforeEach(() => {
      table = document.createElement('table');
      root.appendChild(table);
      mockDimensions(table, { clientWidth: 100, scrollWidth: 500 });

      scaleTablesForPrint(root);
    });

    it('records no scale', () => {
      expect(scaleOf(table)).toBe('');
    });
  });

  describe('with a scale container that holds no target', () => {
    beforeEach(() => {
      const container = document.createElement('div');
      container.dataset.printScaleContainer = '';
      root.appendChild(container);
      mockDimensions(container, { clientWidth: 100, scrollWidth: 500 });
    });

    it('does not throw', () => {
      expect(() => scaleTablesForPrint(root)).not.toThrow();
    });
  });

  describe('with several target tables', () => {
    let narrow;
    let fitting;
    let wide;

    beforeEach(() => {
      narrow = createWrappedTable({ containerWidth: 500, tableWidth: 1000 });
      fitting = createWrappedTable({ containerWidth: 600, tableWidth: 600 });
      wide = createWrappedTable({ containerWidth: 400, tableWidth: 800 });

      scaleTablesForPrint(root);
    });

    it('scales each overflowing table to its own ratio and leaves the rest alone', () => {
      expect(scaleOf(narrow)).toBe('0.5');
      expect(scaleOf(fitting)).toBe('');
      expect(scaleOf(wide)).toBe('0.5');
    });
  });

  describe('when called without a root', () => {
    beforeEach(() => {
      const container = document.createElement('div');
      container.dataset.printScaleContainer = '';
      table = document.createElement('table');
      table.dataset.printScaleTarget = '';
      container.appendChild(table);
      document.body.appendChild(container);

      mockDimensions(container, { clientWidth: 500, scrollWidth: 500 });
      mockDimensions(table, { clientWidth: 1000, scrollWidth: 1000 });

      scaleTablesForPrint();
    });

    it('scales the targets under document.body', () => {
      expect(scaleOf(table)).toBe('0.5');
    });
  });
});

describe('resetScrollForPrint', () => {
  let root;
  let container;
  let restore;

  const createContainer = ({ top, left }) => {
    const el = document.createElement('div');
    el.dataset.printScaleContainer = '';
    root.appendChild(el);
    el.scrollTop = top;
    el.scrollLeft = left;
    return el;
  };

  beforeEach(() => {
    root = document.createElement('div');
    document.body.appendChild(root);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('with a scrolled container', () => {
    beforeEach(() => {
      container = createContainer({ top: 600, left: 200 });

      restore = resetScrollForPrint(root);
    });

    it('scrolls the container back to its origin', () => {
      expect(container.scrollTop).toBe(0);
      expect(container.scrollLeft).toBe(0);
    });

    it('restores the offsets it saved', () => {
      restore();

      expect(container.scrollTop).toBe(600);
      expect(container.scrollLeft).toBe(200);
    });

    it('restores the saved offsets, not whatever the browser left behind', () => {
      container.scrollTop = 2400;
      container.scrollLeft = 800;

      restore();

      expect(container.scrollTop).toBe(600);
      expect(container.scrollLeft).toBe(200);
    });
  });

  describe('with several containers', () => {
    let other;

    beforeEach(() => {
      container = createContainer({ top: 600, left: 200 });
      other = createContainer({ top: 40, left: 0 });

      restore = resetScrollForPrint(root);
    });

    it('resets every container', () => {
      expect(container.scrollTop).toBe(0);
      expect(other.scrollTop).toBe(0);
    });

    it('restores each container to its own offsets', () => {
      restore();

      expect([container.scrollTop, container.scrollLeft]).toEqual([600, 200]);
      expect([other.scrollTop, other.scrollLeft]).toEqual([40, 0]);
    });
  });

  describe('with no containers', () => {
    it('does not throw, and returns a restore that does not throw', () => {
      expect(() => resetScrollForPrint(root)()).not.toThrow();
    });
  });

  describe('when called without a root', () => {
    beforeEach(() => {
      container = createContainer({ top: 300, left: 0 });

      restore = resetScrollForPrint();
    });

    it('resets the containers under document.body', () => {
      expect(container.scrollTop).toBe(0);
    });
  });
});
