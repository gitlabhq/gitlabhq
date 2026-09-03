import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import MarkdownTable from '~/behaviors/components/markdown_table.vue';

describe('MarkdownTable', () => {
  let wrapper;

  // Build the `fields`/`items` props the component expects, as
  // ~/behaviors/markdown/render_markdown_tables would: cells are elements, which
  // the component adopts, and `text` is the sorting comparison key.
  const createCell = (tagName, content) => {
    const cell = document.createElement(tagName);

    if (content instanceof Node) {
      cell.appendChild(content);
    } else {
      cell.textContent = content;
    }

    return cell;
  };

  const buildFields = (headers) =>
    headers.map((content, index) => ({
      key: `col_${index}`,
      cell: createCell('th', content),
      isSortable: true,
    }));

  const buildItems = (fields, rows) =>
    rows.map((contents, rowIndex) => {
      const cells = contents.map((content) => createCell('td', content));
      const item = { cells, rowIndex };

      fields.forEach((field, index) => {
        item[field.key] = { text: cells[index] ? cells[index].textContent.trim() : '' };
      });

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
  const findShadowOverlayWrapper = () => wrapper.findByTestId('table-shadow-overlay');
  const findStickyHeaderWrapper = () => wrapper.find('[data-sticky-header]');
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

    it('adopts the cells it was given, rather than rebuilding them', () => {
      const link = document.createElement('a');
      link.href = '/foo';
      link.textContent = 'Alice';

      createWrapper([[link, '25']]);

      expect(wrapper.find('tbody tr a').element).toBe(link);
    });

    it('adopts header cell content and keeps its alignment', () => {
      const label = document.createElement('code');
      label.textContent = 'Name';

      const fields = buildFields([label, 'Age', 'Height']);
      fields[1].cell.setAttribute('align', 'right');
      fields[2].cell.setAttribute('style', 'text-align: center');

      wrapper = mountExtended(MarkdownTable, {
        propsData: {
          fields,
          items: buildItems(fields, [['Alice', '25', '160cm']]),
          isSortable: true,
        },
      });

      expect(findHeaders().at(0).find('code').element).toBe(label);
      expect(findHeaders().at(1).attributes('align')).toBe('right');
      expect(findHeaders().at(2).attributes('style')).toBe('text-align: center;');
    });
  });

  describe('internal event tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    describe('when canSort is true', () => {
      beforeEach(() => {
        createWrapper([
          ['Charlie', '30'],
          ['Alice', '25'],
          ['Bob', '35'],
        ]);
      });

      it('fires sort_markdown_table_column with ascending direction on first sort', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        await clickHeader(0);

        expect(trackEventSpy).toHaveBeenCalledWith(
          'sort_markdown_table_column',
          { property: 'ascending' },
          undefined,
        );
      });

      it('fires sort_markdown_table_column with descending direction on toggle', async () => {
        await clickHeader(0);

        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        await clickHeader(0);

        expect(trackEventSpy).toHaveBeenCalledWith(
          'sort_markdown_table_column',
          { property: 'descending' },
          undefined,
        );
      });
    });

    describe('when canSort is false', () => {
      it('does not fire sort_markdown_table_column when isSortable is false', async () => {
        createWrapper([['Alice', '25']], { isSortable: false });

        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        await clickHeader(0);

        expect(trackEventSpy).not.toHaveBeenCalled();
      });

      it('does not fire sort_markdown_table_column when there is only one row', async () => {
        createWrapper([['Alice', '25']]);

        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        await clickHeader(0);

        expect(trackEventSpy).not.toHaveBeenCalled();
      });
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
    beforeEach(() => {
      createWrapper([['Alice', '25']], { isSticky: true });
    });

    it('wraps the table in a sticky-header container', () => {
      const stickyWrapper = findStickyHeaderWrapper();
      expect(stickyWrapper.exists()).toBe(true);
      expect(stickyWrapper.find('table').exists()).toBe(true);
    });

    it('wraps the sticky-header container in a shadow overlay wrapper', () => {
      const overlayWrapper = findShadowOverlayWrapper();
      expect(overlayWrapper.exists()).toBe(true);
      expect(overlayWrapper.classes()).toContain('gl-table-shadow-overlay');
      expect(overlayWrapper.find('[data-sticky-header]').exists()).toBe(true);
    });

    it('marks the sticky-header wrapper as the print scale container', () => {
      expect(wrapper.find('[data-print-scale-container]').element).toBe(
        findStickyHeaderWrapper().element,
      );
      expect(wrapper.find('table').attributes('data-print-scale-target')).toBe('');
      expect(wrapper.find('table').attributes('data-print-scale-container')).toBeUndefined();
    });
  });

  describe('when not sticky', () => {
    beforeEach(() => {
      createWrapper([['Alice', '25']], { isSticky: false });
    });

    it('marks the table as its own print scale container', () => {
      const table = wrapper.find('table');
      expect(wrapper.find('[data-print-scale-container]').element).toBe(table.element);
      expect(table.attributes('data-print-scale-target')).toBe('');
      expect(table.attributes('data-print-scale-container')).toBe('');
    });

    it('does not add the shadow overlay wrapper when not sticky', () => {
      expect(findShadowOverlayWrapper().exists()).toBe(false);
    });
  });
});
