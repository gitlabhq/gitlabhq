import markPrintScaleTables from '~/behaviors/markdown/mark_print_scale_tables';

describe('markPrintScaleTables', () => {
  let root;
  let table;

  const createTable = (parent = root) => {
    const el = document.createElement('table');
    parent.appendChild(el);
    return el;
  };

  const createShadowWrapper = () => {
    const wrapper = document.createElement('div');
    wrapper.classList.add('gl-table-shadow');
    root.appendChild(wrapper);
    return wrapper;
  };

  const createStickyWrapper = () => {
    const wrapper = document.createElement('div');
    wrapper.dataset.stickyHeader = '';
    root.appendChild(wrapper);
    return wrapper;
  };

  beforeEach(() => {
    root = document.createElement('div');
    document.body.appendChild(root);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('with a bare table', () => {
    beforeEach(() => {
      table = createTable();

      markPrintScaleTables([table]);
    });

    it('stamps the table as its own scale container and target', () => {
      expect(table.dataset.printScaleContainer).toBe('');
      expect(table.dataset.printScaleTarget).toBe('');
    });
  });

  describe.each([
    ['a .gl-table-shadow wrapper', createShadowWrapper],
    ['a [data-sticky-header] wrapper', createStickyWrapper],
  ])('with a table inside %s', (_, createWrapper) => {
    beforeEach(() => {
      table = createTable(createWrapper());

      markPrintScaleTables([table]);
    });

    it('leaves the table unstamped', () => {
      expect(table.dataset.printScaleContainer).toBeUndefined();
      expect(table.dataset.printScaleTarget).toBeUndefined();
    });
  });

  describe('with a mix of bare and wrapped tables', () => {
    let bare;
    let wrapped;

    beforeEach(() => {
      bare = createTable();
      wrapped = createTable(createShadowWrapper());

      markPrintScaleTables([bare, wrapped]);
    });

    it('stamps only the bare table', () => {
      expect(bare.dataset.printScaleTarget).toBe('');
      expect(wrapped.dataset.printScaleTarget).toBeUndefined();
    });
  });
});
