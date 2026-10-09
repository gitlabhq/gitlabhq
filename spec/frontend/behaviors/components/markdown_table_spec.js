import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { computeAccessibleName } from 'dom-accessibility-api';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
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

  const createWrapper = (
    rows,
    { headers = ['Name', 'Age'], stubTooltip = true, ...props } = {},
  ) => {
    const fields = buildFields(headers);
    const items = buildItems(fields, rows);

    wrapper = mountExtended(MarkdownTable, {
      attachTo: document.body,
      stubs: {
        GlTooltip: stubTooltip
          ? {
              name: 'GlTooltip',
              props: ['target'],
              template: '<span hidden><slot /></span>',
            }
          : jest.requireActual('@gitlab/ui/src/components/base/tooltip/tooltip.vue').default,
      },
      propsData: { fields, items, ...props },
    });
  };

  const createFooterRows = (rows) =>
    rows.map((contents) => contents.map((content) => createCell('td', content)));

  const expectFooter = (text) => {
    const renderedFoot = wrapper.find('table tfoot');
    expect(renderedFoot.exists()).toBe(true);
    expect(renderedFoot.text()).toContain(text);
    expect(wrapper.find('table').element.lastElementChild).toBe(renderedFoot.element);
  };

  const findHeaders = () => wrapper.findAll('thead th');
  const findShadowOverlayWrapper = () => wrapper.findByTestId('table-shadow-overlay');
  const findStickyHeaderWrapper = () => wrapper.find('[data-sticky-header]');
  const getRowTexts = (columnIndex) =>
    wrapper.findAll('tbody tr').wrappers.map((row) => row.findAll('td').at(columnIndex).text());
  const findSortButton = (columnIndex) => findHeaders().at(columnIndex).find('button');
  const findSortIcon = (columnIndex) => findSortButton(columnIndex).findComponent(GlIcon);
  const clickHeader = (columnIndex) => findSortButton(columnIndex).trigger('click');
  const findSortStatus = () => wrapper.findByRole('status');

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
        },
      });

      expect(findHeaders().at(0).find('code').element).toBe(label);
      expect(findHeaders().at(1).attributes('align')).toBe('right');
      expect(findHeaders().at(2).attributes('style')).toBe('text-align: center;');
    });

    it('renders the footer when provided', () => {
      createWrapper([['Alice', '25']], {
        footerRows: createFooterRows([['Average', '25']]),
      });

      expectFooter('Average');
    });

    it('renders no footer element when not provided', () => {
      createWrapper([['Alice', '25']]);

      expect(wrapper.find('table tfoot').exists()).toBe(false);
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

      it('does not report an ascending or descending sort when resetting', async () => {
        await clickHeader(0);
        await clickHeader(0);

        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        trackEventSpy.mockClear();

        await clickHeader(0);

        expect(trackEventSpy).not.toHaveBeenCalled();
      });
    });

    describe('when canSort is false', () => {
      it('does not fire sort_markdown_table_column when there is only one row', async () => {
        createWrapper([['Alice', '25']]);

        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        await findHeaders().at(0).trigger('click');

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

    it('keeps the footer in place when sorting', async () => {
      createWrapper(
        [
          ['Bob', '35'],
          ['Alice', '25'],
        ],
        { footerRows: createFooterRows([['Average', '30']]) },
      );

      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(['Alice', 'Bob']);
      expectFooter('Average');
    });

    it('starts with an empty live region outside the table', () => {
      expect(findSortStatus().text()).toBe('');
      expect(findSortStatus().attributes()).toMatchObject({
        'aria-live': 'polite',
        'aria-atomic': 'true',
      });
      expect(wrapper.find('table [role="status"]').exists()).toBe(false);
    });

    it('announces each sort through the button', async () => {
      const target = findSortButton(0);

      await target.trigger('click');
      expect(findSortStatus().text()).toBe('Name sorted ascending.');

      await target.trigger('click');
      expect(findSortStatus().text()).toBe('Name sorted descending.');

      await target.trigger('click');
      expect(findSortStatus().text()).toBe('Original row order restored.');

      await target.trigger('click');
      expect(findSortStatus().text()).toBe('Name sorted ascending.');
    });

    it('renders a sort button and sets aria-sort to none', () => {
      const header = findHeaders().at(0);
      expect(findSortButton(0).element.tagName).toBe('BUTTON');
      expect(computeAccessibleName(findSortButton(0).element)).toBe('Name');
      expect(computeAccessibleName(findSortButton(1).element)).toBe('Age');
      expect(computeAccessibleName(header.element)).toBe('Name');
      expect(findSortIcon(0).props('name')).toBe('sort-lowest');
      expect(findSortIcon(0).attributes('aria-hidden')).toBe('true');
      expect(header.attributes('tabindex')).toBeUndefined();
      expect(header.attributes('scope')).toBe('col');
      expect(header.attributes('aria-sort')).toBe('none');
    });

    it('sorts when clicking the header text', async () => {
      await wrapper.findByText('Name').trigger('click');

      expect(getRowTexts(0)).toEqual(['Alice', 'Bob', 'Charlie']);
      expect(findHeaders().at(0).attributes('aria-sort')).toBe('ascending');
    });

    it.each(['button', 'svg'])('advances only once per click on the sort %s', async (selector) => {
      const target = findHeaders().at(0).find(selector);

      await target.trigger('click');
      expect(getRowTexts(0)).toEqual(['Alice', 'Bob', 'Charlie']);
      expect(findHeaders().at(0).attributes('aria-sort')).toBe('ascending');

      await target.trigger('click');
      expect(getRowTexts(0)).toEqual(['Charlie', 'Bob', 'Alice']);
      expect(findHeaders().at(0).attributes('aria-sort')).toBe('descending');

      await target.trigger('click');
      expect(getRowTexts(0)).toEqual(['Charlie', 'Alice', 'Bob']);
      expect(findHeaders().at(0).attributes('aria-sort')).toBe('none');
    });

    it.each([
      [1, 'ascending', ['Alice', 'Bob', 'Charlie']],
      [2, 'descending', ['Charlie', 'Bob', 'Alice']],
      [3, 'none', ['Charlie', 'Alice', 'Bob']],
    ])('cycles to %s clicks / %s on the focused button', async (presses, direction, rows) => {
      const header = findHeaders().at(0);
      const button = findSortButton(0);
      button.element.focus();

      for (let index = 0; index < presses; index += 1) {
        button.element.click();
      }
      await nextTick();

      expect(getRowTexts(0)).toEqual(rows);
      expect(header.attributes('aria-sort')).toBe(direction);
      expect(document.activeElement).toBe(button.element);
      expect(computeAccessibleName(header.element)).toBe('Name');
      expect(computeAccessibleName(button.element)).toBe('Name');
      expect(findSortStatus().text()).toBe(
        direction === 'none' ? 'Original row order restored.' : `Name sorted ${direction}.`,
      );
    });

    describe.each(['Enter', ' '])('on %s keydown', (key) => {
      it('leaves native button keyboard activation to the button', async () => {
        const button = findSortButton(0);
        const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
        button.element.dispatchEvent(event);
        await nextTick();

        expect(event.defaultPrevented).toBe(false);
        expect(getRowTexts(0)).toEqual(['Charlie', 'Alice', 'Bob']);

        await button.trigger('click');

        expect(getRowTexts(0)).toEqual(['Alice', 'Bob', 'Charlie']);
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('ascending');
      });
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

      it('offers descending sorting next', () => {
        expect(computeAccessibleName(findSortButton(0).element)).toBe('Name');
        expect(findSortIcon(0).props('name')).toBe('sort-highest');
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

      it('offers resetting next', () => {
        expect(computeAccessibleName(findSortButton(0).element)).toBe('Name');
        expect(findSortIcon(0).props('name')).toBe('redo');
      });
    });

    describe('on third header click', () => {
      beforeEach(async () => {
        await clickHeader(0);
        await clickHeader(0);
        await clickHeader(0);
      });

      it('restores the original order and clears the sort state', () => {
        expect(getRowTexts(0)).toEqual(['Charlie', 'Alice', 'Bob']);
        expect(getRowTexts(1)).toEqual(['30', '25', '35']);
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('none');
        expect(computeAccessibleName(findSortButton(0).element)).toBe('Name');
        expect(findSortIcon(0).props('name')).toBe('sort-lowest');
      });

      it('starts a fresh cycle on the next click', async () => {
        await clickHeader(0);

        expect(getRowTexts(0)).toEqual(['Alice', 'Bob', 'Charlie']);
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('ascending');
      });
    });

    describe('when sorting a new column', () => {
      beforeEach(async () => {
        await clickHeader(0);
        await clickHeader(1);
      });

      it('resets other columns to aria-sort none', () => {
        expect(findHeaders().at(0).attributes('aria-sort')).toBe('none');
        expect(computeAccessibleName(findSortButton(0).element)).toBe('Name');
      });

      it('sets aria-sort on the new column', () => {
        expect(findHeaders().at(1).attributes('aria-sort')).toBe('ascending');
        expect(findSortStatus().text()).toBe('Age sorted ascending.');
      });

      it('restores the original order after sorting multiple columns', async () => {
        await clickHeader(1);
        await clickHeader(1);

        expect(getRowTexts(0)).toEqual(['Charlie', 'Alice', 'Bob']);
        expect(getRowTexts(1)).toEqual(['30', '25', '35']);
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

      it('returns empty cells to their original positions on reset', async () => {
        await clickHeader(1);
        await clickHeader(1);
        await clickHeader(1);

        expect(getRowTexts(1)).toEqual(['', '25', '35']);
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
      await findHeaders().at(0).trigger('click');

      expect(getRowTexts(0)).toEqual(['Alice']);
    });
  });

  describe('with an empty header', () => {
    beforeEach(() => {
      createWrapper(
        [
          ['Bob', '35'],
          ['Alice', '25'],
        ],
        { headers: ['Name', ''] },
      );
    });

    it('announces the column number', async () => {
      expect(computeAccessibleName(findSortButton(1).element)).toBe('Column 2');
      await clickHeader(1);

      expect(findSortStatus().text()).toBe('Column 2 sorted ascending.');
    });
  });

  describe('with a formatted header', () => {
    beforeEach(() => {
      const link = document.createElement('a');
      link.href = '#name';
      const label = document.createElement('strong');
      label.textContent = 'Names & <aliases>';
      link.appendChild(label);
      createWrapper([['Bob'], ['Alice']], { headers: [link] });
    });

    it('announces the adopted header text without markup or escaped entities', async () => {
      await clickHeader(0);
      expect(findSortStatus().text()).toBe('Names & <aliases> sorted ascending.');

      await clickHeader(0);
      expect(findSortStatus().text()).toBe('Names & <aliases> sorted descending.');
      expect(findSortStatus().find('aliases').exists()).toBe(false);
    });
  });

  describe('with duplicate headers', () => {
    beforeEach(() => {
      createWrapper(
        [
          ['Bob', '35'],
          ['Alice', '25'],
        ],
        { headers: ['Name', 'Name'] },
      );
    });

    it('updates the live region when switching columns with the same announcement', async () => {
      await clickHeader(0);
      const announcement = findSortStatus().find('span').element;

      await clickHeader(1);

      expect(findSortStatus().text()).toBe('Name sorted ascending.');
      expect(findSortStatus().find('span').element).not.toBe(announcement);
      expect(findHeaders().at(1).attributes('aria-sort')).toBe('ascending');
    });
  });

  describe('sort tooltips', () => {
    const findSortTooltip = (columnIndex) =>
      wrapper.findAllComponents({ name: 'GlTooltip' }).at(columnIndex);
    const getSortTooltip = (columnIndex) => findSortTooltip(columnIndex).text();

    beforeEach(() => {
      createWrapper([
        ['Charlie', '30'],
        ['Alice', '25'],
        ['Bob', '35'],
      ]);
    });

    it('describes the next action throughout the sort cycle', async () => {
      expect(getSortTooltip(0)).toBe('Sort ascending');
      await clickHeader(0);
      expect(getSortTooltip(0)).toBe('Sort descending');
      await clickHeader(0);
      expect(getSortTooltip(0)).toBe('Reset sorting');
      await clickHeader(0);
      expect(getSortTooltip(0)).toBe('Sort ascending');
    });

    it('updates both tooltips when sorting a different column', async () => {
      await clickHeader(0);
      await clickHeader(1);

      expect(getSortTooltip(0)).toBe('Sort ascending');
      expect(getSortTooltip(1)).toBe('Sort descending');
    });

    it('targets the corresponding sort button', () => {
      [0, 1].forEach((columnIndex) => {
        expect(findSortTooltip(columnIndex).props('target')).toBe(
          findSortButton(columnIndex).attributes('id'),
        );
      });
    });

    it('keeps the icon visible until its tooltip closes', async () => {
      findSortTooltip(0).vm.$emit('show');
      await nextTick();
      await findSortButton(0).trigger('mouseleave');

      expect(findSortIcon(0).classes()).toContain('gl-opacity-10');
      expect(findSortIcon(1).classes()).toContain('gl-opacity-0');

      findSortTooltip(1).vm.$emit('show');
      findSortTooltip(0).vm.$emit('hidden');
      await nextTick();

      expect(findSortIcon(0).classes()).toContain('gl-opacity-0');
      expect(findSortIcon(1).classes()).toContain('gl-opacity-10');

      findSortTooltip(1).vm.$emit('hidden');
      await nextTick();

      expect(findSortIcon(1).classes()).toContain('gl-opacity-0');
    });
  });

  it('renders the real tooltip text throughout the sort cycle', async () => {
    createWrapper(
      [
        ['Bob', '35'],
        ['Alice', '25'],
      ],
      { stubTooltip: false },
    );
    const button = findSortButton(0);
    jest.spyOn(button.element, 'getBoundingClientRect').mockReturnValue({
      x: 0,
      y: 0,
      top: 0,
      left: 0,
      right: 100,
      bottom: 30,
      width: 100,
      height: 30,
    });
    await waitForPromises();
    await button.trigger('mouseenter');
    jest.runOnlyPendingTimers();

    expect(document.querySelector('[role="tooltip"]').textContent.trim()).toBe('Sort ascending');

    await clickHeader(0);
    await waitForPromises();
    expect(document.querySelector('[role="tooltip"]').textContent.trim()).toBe('Sort descending');

    await clickHeader(0);
    await waitForPromises();
    expect(document.querySelector('[role="tooltip"]').textContent.trim()).toBe('Reset sorting');
  });

  describe('with duplicate values', () => {
    beforeEach(() => {
      createWrapper([
        ['Bob', 'first'],
        ['Alice', 'second'],
        ['Bob', 'third'],
      ]);
    });

    it('restores each original row and cell after a full cycle', async () => {
      const rows = wrapper.findAll('tbody tr').wrappers.map((row) => row.element);
      const cells = wrapper.findAll('tbody td').wrappers.map((cell) => cell.element);

      await clickHeader(0);
      await clickHeader(0);
      await clickHeader(0);

      expect(getRowTexts(1)).toEqual(['first', 'second', 'third']);
      wrapper.findAll('tbody tr').wrappers.forEach((row, index) => {
        expect(row.element).toBe(rows[index]);
      });
      wrapper.findAll('tbody td').wrappers.forEach((cell, index) => {
        expect(cell.element).toBe(cells[index]);
      });
    });
  });

  describe('with a link in the header', () => {
    it.each(['Enter', ' '])('does not intercept %s on the link', async (key) => {
      const link = document.createElement('a');
      link.href = '#name';
      link.textContent = 'Name';
      createWrapper([['Bob'], ['Alice']], { headers: [link] });
      const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });

      link.dispatchEvent(event);
      await nextTick();

      expect(event.defaultPrevented).toBe(false);
      expect(getRowTexts(0)).toEqual(['Bob', 'Alice']);
      expect(findHeaders().at(0).attributes('aria-sort')).toBe('none');
      expect(findSortStatus().text()).toBe('');
    });

    it.each(['a', 'a strong'])('keeps %s interactive without sorting', async (selector) => {
      const link = document.createElement('a');
      link.href = '#name';
      const label = document.createElement('strong');
      label.textContent = 'Name';
      link.appendChild(label);
      const onClick = jest.fn();
      link.addEventListener('click', onClick);
      createWrapper([['Bob'], ['Alice']], { headers: [link] });

      await wrapper.find(`thead ${selector}`).trigger('click');

      expect(onClick).toHaveBeenCalledTimes(1);
      expect(wrapper.find('thead a').element).toBe(link);
      expect(findSortButton(0).find('a').exists()).toBe(false);
      expect(computeAccessibleName(findSortButton(0).element)).toBe('Name');
      expect(computeAccessibleName(findHeaders().at(0).element)).toBe('Name');
      expect(getRowTexts(0)).toEqual(['Bob', 'Alice']);
      expect(findHeaders().at(0).attributes('aria-sort')).toBe('none');
      expect(findSortStatus().text()).toBe('');
    });
  });

  describe.each([0, 1, 1001])('with %i rows', (rowCount) => {
    beforeEach(() => {
      createWrapper(Array.from({ length: rowCount }, (_, index) => [`Row ${index}`, '']));
    });

    it('does not render sort buttons', () => {
      expect(wrapper.find('button').exists()).toBe(false);
      expect(findSortStatus().exists()).toBe(false);
    });
  });

  describe('with 1000 rows', () => {
    beforeEach(() => {
      createWrapper(Array.from({ length: 1000 }, (_, index) => [`Row ${index}`, '']));
    });

    it('supports sorting and restoring the original order', async () => {
      const originalOrder = getRowTexts(0);
      await clickHeader(0);
      expect(getRowTexts(0)).not.toEqual(originalOrder);
      await clickHeader(0);
      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(originalOrder);
    });
  });

  describe('sticky header', () => {
    beforeEach(() => {
      createWrapper([['Alice', '25']]);
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
});
