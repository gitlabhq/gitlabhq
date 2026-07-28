import { mountExtended } from 'helpers/vue_test_utils_helper';
import MarkdownTable from '~/behaviors/components/markdown_table.vue';

describe('MarkdownTable', () => {
  let wrapper;

  // Build the plain `fields`/`items` props the component expects. Each header
  // becomes `{ key, label }`; each cell becomes `{ html, text }` where `text`
  // is derived from the (HTML-stripped) cell content for sorting comparisons.
  const buildFields = (headers) => headers.map((label, index) => ({ key: `col_${index}`, label }));

  const buildItems = (fields, rows) =>
    rows.map((cells, rowIndex) => {
      const item = {};
      fields.forEach((field, index) => {
        const html = cells[index] ?? '';
        const text = html.replace(/<[^>]*>/g, '').trim();
        item[field.key] = { html, text };
      });
      item.rowIndex = rowIndex;
      return item;
    });

  const createWrapper = (rows, { headers = ['Name', 'Age'], ...props } = {}) => {
    const fields = buildFields(headers);
    const items = buildItems(fields, rows);

    wrapper = mountExtended(MarkdownTable, {
      propsData: { fields, items, isSortable: true, ...props },
    });
  };

  const findHeaders = () => wrapper.findAll('thead th');
  const getRowTexts = (columnIndex) =>
    wrapper.findAll('tbody tr').wrappers.map((row) => row.findAll('td').at(columnIndex).text());
  const clickHeader = (columnIndex) => findHeaders().at(columnIndex).trigger('click');

  describe('rendering', () => {
    it('renders a plain table (not GlTable) with the provided headers', () => {
      createWrapper([['Alice', '25']]);

      expect(wrapper.find('table').exists()).toBe(true);
      expect(wrapper.findComponent({ name: 'GlTable' }).exists()).toBe(false);

      const headers = findHeaders().wrappers.map((th) => th.text());
      expect(headers[0]).toContain('Name');
      expect(headers[1]).toContain('Age');
    });

    it('renders cell HTML content', () => {
      createWrapper([['<a href="/foo">Alice</a>', '25']]);

      expect(wrapper.find('tbody tr a').attributes('href')).toBe('/foo');
    });
  });

  describe('when sortable', () => {
    beforeEach(() => {
      createWrapper([
        ['Charlie', '30'],
        ['Alice', '25'],
        ['Bob', '35'],
      ]);
    });

    it('renders rows in original order', () => {
      expect(getRowTexts(0)).toEqual(['Charlie', 'Alice', 'Bob']);
    });

    it('makes headers focusable and sets aria-sort to none', () => {
      const header = findHeaders().at(0);
      expect(header.attributes('tabindex')).toBe('0');
      expect(header.attributes('aria-sort')).toBe('none');
      expect(header.classes()).toContain('gl-cursor-pointer');
    });

    describe('on first header click', () => {
      beforeEach(async () => {
        await clickHeader(0);
      });

      it('sorts ascending', () => {
        expect(getRowTexts(0)).toEqual(['Alice', 'Bob', 'Charlie']);
      });

      it('sets aria-sort to ascending', () => {
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('ascending');
      });
    });

    describe('on second header click', () => {
      beforeEach(async () => {
        await clickHeader(0);
        await clickHeader(0);
      });

      it('sorts descending', () => {
        expect(getRowTexts(0)).toEqual(['Charlie', 'Bob', 'Alice']);
      });

      it('sets aria-sort to descending', () => {
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('descending');
      });
    });

    describe('when sorting a new column', () => {
      beforeEach(async () => {
        await clickHeader(0);
        await clickHeader(1);
      });

      it('resets other columns to aria-sort none', () => {
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('none');
      });

      it('sets aria-sort on the new column', () => {
        expect(findHeaders().at(1).attributes('aria-sort')).toBe('ascending');
      });
    });

    describe('on keyboard activation', () => {
      beforeEach(() => {
        createWrapper([
          ['Bob', ''],
          ['Alice', ''],
        ]);
      });

      it('sorts on Enter', async () => {
        await findHeaders().at(0).trigger('keydown.enter');

        expect(getRowTexts(0)).toEqual(['Alice', 'Bob']);
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('ascending');
      });

      it('sorts on Space', async () => {
        await findHeaders().at(0).trigger('keydown.space');

        expect(getRowTexts(0)).toEqual(['Alice', 'Bob']);
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('ascending');
      });
    });

    it('sorts strings containing numbers as strings, not numerically', async () => {
      createWrapper([
        ['Definitely not 100', ''],
        ['2 and 1/2 men', ''],
        ['Alpha', ''],
      ]);

      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(['2 and 1/2 men', 'Alpha', 'Definitely not 100']);
    });

    describe('with empty cells', () => {
      beforeEach(() => {
        createWrapper([
          ['Charlie', ''],
          ['Alice', '25'],
          ['Bob', '35'],
        ]);
      });

      it('sorts empty cells to the end when ascending', async () => {
        await clickHeader(1);

        expect(getRowTexts(1)).toEqual(['25', '35', '']);
      });

      it('sorts empty cells to the end when descending', async () => {
        await clickHeader(1);
        await clickHeader(1);

        expect(getRowTexts(1)).toEqual(['35', '25', '']);
      });
    });

    describe('across sequential sorts on different columns', () => {
      // Regression: rows are keyed on the stable `rowIndex` (original markdown
      // order) rather than their position in `sortedItems`. With an index key,
      // Vue patches rows in place instead of reordering them, so cells from one
      // row can leak into another when sorting one column then another. Sorting
      // a column, then a different column, must keep each row's cells together.
      it('keeps a row cells together', async () => {
        await clickHeader(0);
        expect(getRowTexts(0)).toEqual(['Alice', 'Bob', 'Charlie']);
        expect(getRowTexts(1)).toEqual(['25', '35', '30']);

        await clickHeader(1);
        expect(getRowTexts(0)).toEqual(['Alice', 'Charlie', 'Bob']);
        expect(getRowTexts(1)).toEqual(['25', '30', '35']);
      });
    });
  });

  describe('when sortable but only one row', () => {
    beforeEach(() => {
      createWrapper([['Alice', '25']]);
    });

    it('does not render sort affordances', () => {
      const header = findHeaders().at(0);
      expect(header.attributes('tabindex')).toBeUndefined();
      expect(header.attributes('aria-sort')).toBeUndefined();
      expect(header.classes()).not.toContain('gl-cursor-pointer');
      expect(wrapper.find('[data-sort-icon]').exists()).toBe(false);
      expect(wrapper.find('.gl-sr-only').exists()).toBe(false);
    });

    it('does not sort when a header is clicked', async () => {
      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(['Alice']);
    });
  });

  describe('when not sortable (sticky only)', () => {
    const createNonSortable = (rows) => createWrapper(rows, { isSortable: false });

    it('renders plain headers without sort affordances', () => {
      createNonSortable([['Alice', '25']]);

      const header = findHeaders().at(0);
      expect(header.attributes('tabindex')).toBeUndefined();
      expect(header.attributes('aria-sort')).toBeUndefined();
      expect(header.classes()).not.toContain('gl-cursor-pointer');
      expect(wrapper.find('[data-sort-icon]').exists()).toBe(false);
      expect(wrapper.find('.gl-sr-only').exists()).toBe(false);
    });

    it('does not sort when a header is clicked', async () => {
      createNonSortable([
        ['Charlie', '30'],
        ['Alice', '25'],
        ['Bob', '35'],
      ]);

      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(['Charlie', 'Alice', 'Bob']);
    });
  });

  describe('when sticky', () => {
    it('wraps the table in a sticky-header container', () => {
      createWrapper([['Alice', '25']], { isSticky: true });

      const stickyWrapper = wrapper.find('[data-sticky-header]');
      expect(stickyWrapper.exists()).toBe(true);
      expect(stickyWrapper.find('table').exists()).toBe(true);
    });
  });
});
