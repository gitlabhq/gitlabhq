import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { computeAccessibleName } from 'dom-accessibility-api';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import MarkdownTable from '~/behaviors/components/markdown_table.vue';
import AccessorUtilities from '~/lib/utils/accessor';

describe('MarkdownTable', () => {
  let wrapper;

  const createCell = (tagName, content) => {
    const cell = document.createElement(tagName);

    if (content instanceof Node) {
      cell.appendChild(content);
    } else {
      cell.textContent = content;
    }

    return cell;
  };

  const createRow = (tagName, contents, rowIndex = 0) => ({
    rowIndex,
    attributes: {},
    cells: contents.map((content) => createCell(tagName, content)),
  });

  const createRows = (tagName, rows) =>
    rows.map((contents, rowIndex) => createRow(tagName, contents, rowIndex));

  const createSection = (tagName, rows, attributes = {}) => ({ tagName, attributes, rows });

  const buildFields = (headers) =>
    headers.map((content, index) => ({
      key: `col_${index}`,
      cell: createCell('th', content),
      attributes: {},
    }));

  const buildItems = (fields, rows) =>
    rows.map((contents, rowIndex) => {
      const item = createRow('td', contents, rowIndex);

      fields.forEach((field, index) => {
        item[field.key] = { text: item.cells[index] ? item.cells[index].textContent.trim() : '' };
      });

      return item;
    });

  const createCaption = (text) => {
    const caption = document.createElement('caption');
    caption.textContent = text;
    return caption;
  };

  const expectCaption = (text) => {
    const renderedCaption = wrapper.find('table caption');
    expect(renderedCaption.exists()).toBe(true);
    expect(renderedCaption.text()).toBe(text);
    expect(wrapper.find('table').element.firstElementChild).toBe(renderedCaption.element);
  };

  const createFoot = (rows) => createSection('tfoot', createRows('td', rows));

  const expectFooter = (text) => {
    const renderedFoot = wrapper.find('table tfoot');
    expect(renderedFoot.exists()).toBe(true);
    expect(renderedFoot.text()).toContain(text);
    expect(wrapper.find('table').element.lastElementChild).toBe(renderedFoot.element);
  };

  const createWrapper = (
    rows,
    {
      headers = ['Name', 'Age'],
      stubTooltip = true,
      attachTo = document.body,
      head,
      foot,
      ...props
    } = {},
  ) => {
    const fields = buildFields(headers);
    const defaultHead = fields.length ? [createSection('thead', [])] : [];
    const sections = [
      ...(head ? [head] : defaultHead),
      createSection('tbody', buildItems(fields, rows)),
      ...(foot ? [foot] : []),
    ];

    wrapper = mountExtended(MarkdownTable, {
      attachTo,
      directives: { GlResizeObserver: createMockDirective('gl-resize-observer') },
      stubs: {
        GlTooltip: stubTooltip
          ? {
              name: 'GlTooltip',
              props: ['target'],
              template: '<span hidden><slot /></span>',
            }
          : jest.requireActual('@gitlab/ui/src/components/base/tooltip/tooltip.vue').default,
      },
      propsData: { fields, sections, ...props },
    });
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
  const findHeightToggle = () => wrapper.findComponentByTestId('markdown-table-height-toggle');

  const resizeTable = async (height) => {
    const table = wrapper.find('table').element;
    Object.defineProperty(table, 'offsetHeight', { configurable: true, value: height });
    getBinding(table, 'gl-resize-observer').value();
    await nextTick();
  };

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

    it('adopts header cell content and attributes', () => {
      const label = document.createElement('code');
      label.textContent = 'Name';

      const fields = buildFields([label, 'Age', 'Height']);
      fields[1].attributes = { align: 'right' };
      fields[2].attributes = { style: 'text-align: center', class: 'task-table-item' };

      wrapper = mountExtended(MarkdownTable, {
        propsData: {
          fields,
          sections: [
            createSection('thead', []),
            createSection('tbody', buildItems(fields, [['Alice', '25', '160cm']])),
          ],
        },
      });

      expect(findHeaders().at(0).find('code').element).toBe(label);
      expect(findHeaders().at(1).attributes('align')).toBe('right');
      expect(findHeaders().at(2).attributes('style')).toBe('text-align: center;');
      expect(findHeaders().at(2).classes()).toEqual(
        expect.arrayContaining(['task-table-item', 'gl-group/markdown-table-header']),
      );
    });

    it('keeps its own header cell attributes over adopted ones', () => {
      const fields = buildFields(['Name', 'Age']);
      fields[0].attributes = { 'aria-sort': 'descending', scope: 'row' };

      wrapper = mountExtended(MarkdownTable, {
        propsData: {
          fields,
          sections: [
            createSection('thead', []),
            createSection('tbody', buildItems(fields, [['Alice', '25']])),
          ],
        },
      });

      expect(findHeaders().at(0).attributes('aria-sort')).toBe('none');
      expect(findHeaders().at(0).attributes('scope')).toBe('col');
    });

    it('renders the caption and footer, caption first and footer last', () => {
      createWrapper([['Alice', '25']], {
        caption: createCaption('Team members'),
        foot: createFoot([['Average', '25']]),
      });

      expectCaption('Team members');
      expectFooter('Average');
      expect(Array.from(wrapper.find('table').element.children, (el) => el.tagName)).toEqual([
        'CAPTION',
        'THEAD',
        'TBODY',
        'TFOOT',
      ]);
    });

    it('renders neither a caption nor a footer when not provided', () => {
      createWrapper([['Alice', '25']]);

      expect(wrapper.find('table caption').exists()).toBe(false);
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
      it('does not fire sort_markdown_table_column when a header is clicked', async () => {
        createWrapper([['Alice', '25']], {
          headers: [],
          head: createSection('thead', createRows('th', [['Name', 'Age']])),
        });

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

    it('keeps the caption and footer in place when sorting', async () => {
      createWrapper(
        [
          ['Bob', '35'],
          ['Alice', '25'],
        ],
        {
          caption: createCaption('Team members'),
          foot: createFoot([['Average', '30']]),
        },
      );

      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(['Alice', 'Bob']);
      expectCaption('Team members');
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

  describe('when not sortable', () => {
    let head;

    beforeEach(() => {
      head = createSection(
        'thead',
        createRows('th', [
          ['Name', 'Age'],
          ['First', 'Years'],
        ]),
      );
      createWrapper(
        [
          ['Bob', '35'],
          ['Alice', '25'],
        ],
        { headers: [], head },
      );
    });

    it('adopts the header rows without sort affordances', () => {
      const headers = findHeaders().wrappers.map((th) => th.element);
      const headCells = head.rows.flatMap((row) => row.cells);
      expect(headers).toHaveLength(4);
      headers.forEach((header, index) => expect(header).toBe(headCells[index]));
      expect(findHeaders().at(0).attributes('aria-sort')).toBeUndefined();
      expect(wrapper.find('thead button').exists()).toBe(false);
      expect(wrapper.find('[data-sort-icon]').exists()).toBe(false);
      expect(findSortStatus().exists()).toBe(false);
    });

    it('does not sort when a header is clicked', async () => {
      await findHeaders().at(0).trigger('click');

      expect(getRowTexts(0)).toEqual(['Bob', 'Alice']);
    });
  });

  describe('without a header', () => {
    beforeEach(() => {
      createWrapper([['Alice', '25']], { headers: [] });
    });

    it('renders no table head', () => {
      expect(wrapper.find('thead').exists()).toBe(false);
      expect(getRowTexts(0)).toEqual(['Alice']);
    });
  });

  describe('with multiple bodies', () => {
    beforeEach(() => {
      createWrapper([], {
        headers: [],
        sections: [
          createSection('tbody', buildItems([], [['Bob']])),
          createSection('tbody', buildItems([], [['Alice']])),
        ],
      });
    });

    it('renders each body in order', () => {
      const bodies = wrapper.findAll('tbody');
      expect(bodies).toHaveLength(2);
      expect(bodies.at(0).text()).toBe('Bob');
      expect(bodies.at(1).text()).toBe('Alice');
    });
  });

  describe('with the footer before the body', () => {
    beforeEach(() => {
      const fields = buildFields(['Name', 'Age']);
      createWrapper([], {
        sections: [
          createSection('thead', []),
          createFoot([['Average', '30']]),
          createSection(
            'tbody',
            buildItems(fields, [
              ['Bob', '35'],
              ['Alice', '25'],
            ]),
          ),
        ],
      });
    });

    it('keeps the sections in that order', () => {
      expect(Array.from(wrapper.find('table').element.children, (el) => el.tagName)).toEqual([
        'THEAD',
        'TFOOT',
        'TBODY',
      ]);
    });

    it('still sorts the body', async () => {
      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(['Alice', 'Bob']);
      expect(wrapper.find('tfoot').text()).toContain('Average');
    });
  });

  describe('with section attributes', () => {
    beforeEach(() => {
      createWrapper([['Alice', '25']], {
        sections: [
          createSection('thead', [], { 'data-sourcepos': '1:1-1:9' }),
          createSection('tbody', buildItems(buildFields(['Name', 'Age']), [['Alice', '25']]), {
            dir: 'rtl',
            lang: 'ar',
          }),
        ],
      });
    });

    it('sets them on the rendered sections', () => {
      expect(wrapper.find('thead').attributes('data-sourcepos')).toBe('1:1-1:9');
      expect(wrapper.find('tbody').attributes()).toMatchObject({ dir: 'rtl', lang: 'ar' });
    });
  });

  describe('with row attributes', () => {
    beforeEach(() => {
      const items = buildItems(buildFields(['Name', 'Age']), [
        ['Bob', '35'],
        ['Alice', '25'],
      ]);
      items[0].attributes = { align: 'right', lang: 'ar', 'data-sourcepos': '3:1-3:9' };
      createWrapper([], {
        headerRowAttributes: { align: 'center' },
        sections: [createSection('thead', []), createSection('tbody', items)],
      });
    });

    it('sets them on the rendered rows', () => {
      expect(wrapper.find('thead tr').attributes('align')).toBe('center');
      expect(wrapper.findAll('tbody tr').at(0).attributes()).toMatchObject({
        align: 'right',
        lang: 'ar',
        'data-sourcepos': '3:1-3:9',
      });
      expect(wrapper.findAll('tbody tr').at(1).attributes('lang')).toBeUndefined();
    });

    it('keeps them with their row across a sort', async () => {
      await clickHeader(0);

      expect(getRowTexts(0)).toEqual(['Alice', 'Bob']);
      expect(wrapper.findAll('tbody tr').at(0).attributes('lang')).toBeUndefined();
      expect(wrapper.findAll('tbody tr').at(1).attributes('lang')).toBe('ar');
    });
  });

  describe('with table attributes', () => {
    beforeEach(() => {
      createWrapper([['Alice', '25']], {
        tableAttributes: { class: 'tableblock stripes-even', 'data-sourcepos': '1:1-4:9' },
      });
    });

    it('sets them on the table', () => {
      expect(wrapper.find('table').attributes('data-sourcepos')).toBe('1:1-4:9');
    });

    it('merges classes with its own', () => {
      expect(wrapper.find('table').classes()).toEqual(
        expect.arrayContaining(['tableblock', 'stripes-even', 'gl-min-w-full']),
      );
    });
  });

  describe('with a direction', () => {
    beforeEach(() => {
      createWrapper([['Alice', '25']], { dir: 'auto' });
    });

    it('sets it on the wrapper so scrolling and shadows follow the table', () => {
      expect(findShadowOverlayWrapper().attributes('dir')).toBe('auto');
      expect(wrapper.find('table').attributes('dir')).toBeUndefined();
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

  describe('height toggle', () => {
    useLocalStorageSpy();
    useFakeRequestAnimationFrame();
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    const MAX_HEIGHT_CLASS = 'gl-max-h-[70vh]';
    const SHORT_TABLE_HEIGHT = 100;
    const TALL_TABLE_HEIGHT = 1000;

    let panel;
    let panelContent;

    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);

      panel = document.createElement('div');
      panel.classList.add('js-static-panel-inner');
      panel.scrollBy = jest.fn();
      panelContent = document.createElement('div');
      panel.appendChild(panelContent);
      document.body.appendChild(panel);
    });

    afterEach(() => {
      panel.remove();
    });

    describe('with no stored preference', () => {
      beforeEach(() => {
        createWrapper([['Alice', '25']], { attachTo: panelContent });
      });

      it('caps the table height', () => {
        expect(findStickyHeaderWrapper().classes()).toContain(MAX_HEIGHT_CLASS);
      });

      it('keeps the other sticky-header classes', () => {
        expect(findStickyHeaderWrapper().classes()).toEqual(
          expect.arrayContaining([
            'gl-w-fit',
            'gl-max-w-full',
            'gl-overflow-x-auto',
            'gl-overflow-y-auto',
            'print:gl-max-h-none',
          ]),
        );
      });

      it('does not render the toggle before the table is measured', () => {
        expect(findHeightToggle().exists()).toBe(false);
      });

      describe('when the table resizes', () => {
        let runFrame;

        beforeEach(async () => {
          jest.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => {
            runFrame = callback;
            return 42;
          });
          await resizeTable(TALL_TABLE_HEIGHT);
        });

        it('does not render the toggle before the next animation frame', () => {
          expect(findHeightToggle().exists()).toBe(false);
        });

        describe('on the next animation frame', () => {
          beforeEach(async () => {
            runFrame();
            await nextTick();
          });

          it('renders the toggle', () => {
            expect(findHeightToggle().exists()).toBe(true);
          });
        });

        describe('when destroyed before the next animation frame', () => {
          beforeEach(() => {
            jest.spyOn(window, 'cancelAnimationFrame');
            wrapper.destroy();
          });

          it('cancels the pending measurement', () => {
            expect(window.cancelAnimationFrame).toHaveBeenCalledWith(42);
          });
        });
      });

      describe('when the table fits within the height cap', () => {
        beforeEach(async () => {
          await resizeTable(SHORT_TABLE_HEIGHT);
        });

        it('does not render the toggle', () => {
          expect(findHeightToggle().exists()).toBe(false);
        });
      });

      describe('when the table is taller than the height cap', () => {
        beforeEach(async () => {
          await resizeTable(TALL_TABLE_HEIGHT);
        });

        it('renders the toggle outside the shadow overlay', () => {
          expect(findHeightToggle().exists()).toBe(true);
          expect(findShadowOverlayWrapper().element.contains(findHeightToggle().element)).toBe(
            false,
          );
        });

        it('shows the expand action', () => {
          expect(findHeightToggle().text()).toBe('Show full table');
          expect(findHeightToggle().props('icon')).toBe('expand');
          expect(findHeightToggle().attributes('aria-expanded')).toBe('false');
        });

        it('points the toggle at the scroll container', () => {
          expect(findHeightToggle().attributes('aria-controls')).toBe(
            findStickyHeaderWrapper().attributes('id'),
          );
        });

        describe('when the toggle is clicked', () => {
          let trackEventSpy;

          beforeEach(async () => {
            ({ trackEventSpy } = bindInternalEventDocument(wrapper.element));
            await findHeightToggle().vm.$emit('click');
          });

          it('removes the height cap', () => {
            expect(findStickyHeaderWrapper().classes()).not.toContain(MAX_HEIGHT_CLASS);
            expect(findStickyHeaderWrapper().classes()).toContain('print:gl-max-h-none');
          });

          it('shows the collapse action', () => {
            expect(findHeightToggle().text()).toBe('Collapse table');
            expect(findHeightToggle().props('icon')).toBe('collapse');
            expect(findHeightToggle().attributes('aria-expanded')).toBe('true');
          });

          it('stores the preference', () => {
            expect(localStorage.setItem).toHaveBeenCalledWith('markdown_table_expanded', 'true');
          });

          it('tracks the expansion', () => {
            expect(trackEventSpy).toHaveBeenCalledWith(
              'toggle_markdown_table_full_height',
              { property: 'expanded' },
              undefined,
            );
          });

          describe('when the toggle is clicked again', () => {
            beforeEach(async () => {
              jest
                .spyOn(findHeightToggle().element, 'getBoundingClientRect')
                .mockReturnValueOnce({ top: 900 })
                .mockReturnValueOnce({ top: 100 });

              findHeightToggle().vm.$emit('click');
              await waitForPromises();
            });

            it('restores the height cap', () => {
              expect(findStickyHeaderWrapper().classes()).toContain(MAX_HEIGHT_CLASS);
              expect(findHeightToggle().attributes('aria-expanded')).toBe('false');
            });

            it('stores the preference', () => {
              expect(localStorage.setItem).toHaveBeenLastCalledWith(
                'markdown_table_expanded',
                'false',
              );
            });

            it('tracks the collapse', () => {
              expect(trackEventSpy).toHaveBeenLastCalledWith(
                'toggle_markdown_table_full_height',
                { property: 'collapsed' },
                undefined,
              );
            });

            it('scrolls the panel to keep the toggle where it was', () => {
              expect(panel.scrollBy).toHaveBeenCalledWith({ top: -800 });
            });
          });
        });

        describe('when the viewport grows to fit the table', () => {
          const { innerHeight } = window;

          beforeEach(async () => {
            window.innerHeight = TALL_TABLE_HEIGHT * 2;
            window.dispatchEvent(new Event('resize'));
            await nextTick();
          });

          afterEach(() => {
            window.innerHeight = innerHeight;
          });

          it('hides the toggle', () => {
            expect(findHeightToggle().exists()).toBe(false);
          });
        });
      });
    });

    describe('with an expanded preference stored', () => {
      beforeEach(async () => {
        localStorage.setItem('markdown_table_expanded', 'true');
        createWrapper([['Alice', '25']]);
        await resizeTable(TALL_TABLE_HEIGHT);
      });

      it('renders at full height', () => {
        expect(findStickyHeaderWrapper().classes()).not.toContain(MAX_HEIGHT_CLASS);
        expect(findHeightToggle().attributes('aria-expanded')).toBe('true');
      });
    });

    describe('with another table on the page', () => {
      let otherWrapper;

      beforeEach(async () => {
        createWrapper([['Bob', '35']]);
        otherWrapper = wrapper;
        createWrapper([['Alice', '25']]);
        await resizeTable(TALL_TABLE_HEIGHT);
      });

      describe('when the toggle is clicked', () => {
        beforeEach(async () => {
          jest
            .spyOn(wrapper.element, 'getBoundingClientRect')
            .mockReturnValueOnce({ top: 300 })
            .mockReturnValueOnce({ top: 1100 });

          findHeightToggle().vm.$emit('click');
          await waitForPromises();
        });

        it('removes the height cap from the other table', () => {
          expect(otherWrapper.find('[data-sticky-header]').classes()).not.toContain(
            MAX_HEIGHT_CLASS,
          );
        });

        it('scrolls the panel to keep the clicked table where it was', () => {
          expect(panel.scrollBy).toHaveBeenCalledWith({ top: 800 });
        });
      });

      describe('when the other table is destroyed', () => {
        beforeEach(() => {
          jest.spyOn(window, 'removeEventListener');
          otherWrapper.destroy();
        });

        it('stops listening for preference and viewport changes', () => {
          expect(window.removeEventListener).toHaveBeenCalledWith(
            'gl-markdown-table-expanded',
            expect.any(Function),
          );
          expect(window.removeEventListener).toHaveBeenCalledWith('resize', expect.any(Function));
        });
      });
    });

    describe('when local storage is unavailable', () => {
      beforeEach(async () => {
        AccessorUtilities.canUseLocalStorage.mockReturnValue(false);
        createWrapper([['Alice', '25']]);
        await resizeTable(TALL_TABLE_HEIGHT);
      });

      it('defaults to the capped height without reading local storage', () => {
        expect(localStorage.getItem).not.toHaveBeenCalled();
        expect(findStickyHeaderWrapper().classes()).toContain(MAX_HEIGHT_CLASS);
      });

      describe('when the toggle is clicked', () => {
        beforeEach(async () => {
          await findHeightToggle().vm.$emit('click');
        });

        it('toggles without writing to local storage', () => {
          expect(findStickyHeaderWrapper().classes()).not.toContain(MAX_HEIGHT_CLASS);
          expect(localStorage.setItem).not.toHaveBeenCalled();
        });
      });
    });
  });
});
