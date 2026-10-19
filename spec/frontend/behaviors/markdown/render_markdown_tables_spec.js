import renderMarkdownTables from '~/behaviors/markdown/render_markdown_tables';
import waitForPromises from 'helpers/wait_for_promises';

const mockMarkdownTableDestroyed = jest.fn();

// The real component, with a `destroyed` hook so the cleanup below is observable.
// It has to be the real one: these tests are about which nodes end up in the
// mounted table, which is the component's job.
jest.mock('~/behaviors/components/markdown_table.vue', () => ({
  __esModule: true,
  default: {
    ...jest.requireActual('~/behaviors/components/markdown_table.vue').default,
    destroyed: mockMarkdownTableDestroyed,
  },
}));

function createCell(tagName, content) {
  const cell = document.createElement(tagName);

  if (content instanceof Node) {
    cell.appendChild(content);
  } else {
    cell.textContent = content;
  }

  return cell;
}

function createRow(tagName, contents) {
  const row = document.createElement('tr');
  contents.forEach((content) => row.appendChild(createCell(tagName, content)));
  return row;
}

function createSection(tagName, rows) {
  const section = document.createElement(tagName);
  rows.forEach((row) => section.appendChild(row));
  return section;
}

function buildTableFrom({ head = [], bodies = [], foot = [] }) {
  const table = document.createElement('table');

  if (head.length) table.appendChild(createSection('thead', head));
  bodies.forEach((rows) => table.appendChild(createSection('tbody', rows)));
  if (foot.length) table.appendChild(createSection('tfoot', foot));

  return table;
}

function createTable({ headers = ['Name', 'Age'], rows = [] } = {}) {
  return buildTableFrom({
    head: [createRow('th', headers)],
    bodies: [rows.map((contents) => createRow('td', contents))],
  });
}

function appendTable(table) {
  const container = document.createElement('div');
  container.className = 'md';
  container.appendChild(table);
  document.body.appendChild(container);
  return container;
}

const buildTable = () =>
  createTable({
    rows: [
      ['Alice', '25'],
      ['Bob', '35'],
    ],
  });

const headerRow = () => createRow('th', ['Name', 'Age']);
const bodyRows = () => [createRow('td', ['Bob', '35']), createRow('td', ['Alice', '25'])];

const findRendered = (container) => container.querySelector('table');
const findWrapper = (container) => container.querySelector('[data-testid="table-shadow-overlay"]');
const findSortButtons = (container) => container.querySelectorAll('thead th button');
const findStickyWrappers = (container) => container.querySelectorAll('[data-sticky-header]');
const cellTexts = (rows) =>
  Array.from(rows, (row) => Array.from(row.cells, (cell) => cell.textContent));
const cellsOf = (rows) => rows.map((row) => Array.from(row.cells));
const expectSameCells = (rows, expectedCells) => {
  expect(cellsOf(Array.from(rows)).map((cells) => cells.length)).toEqual(
    expectedCells.map((cells) => cells.length),
  );
  cellsOf(Array.from(rows))
    .flat()
    .forEach((cell, index) => expect(cell).toBe(expectedCells.flat()[index]));
};

describe('renderMarkdownTables', () => {
  beforeEach(() => {
    mockMarkdownTableDestroyed.mockClear();
  });

  afterEach(async () => {
    document.body.innerHTML = '';
    await waitForPromises();
  });

  describe('claiming', () => {
    it('processes multiple tables', async () => {
      const table1 = buildTable();
      const table2 = buildTable();
      const container1 = appendTable(table1);
      const container2 = appendTable(table2);

      await renderMarkdownTables([table1, table2]);

      expect(container1.contains(table1)).toBe(false);
      expect(container2.contains(table2)).toBe(false);
      expect(findRendered(container1)).not.toBeNull();
      expect(findRendered(container2)).not.toBeNull();
    });

    it('does not mount the same table twice', async () => {
      const table = buildTable();
      const container = appendTable(table);

      await renderMarkdownTables([table]);
      const firstTable = findRendered(container);

      expect(renderMarkdownTables([table])).toBeNull();
      expect(container.querySelectorAll('table')).toHaveLength(1);
      expect(findRendered(container)).toBe(firstTable);
    });

    it('does not re-mount the table rendered by the component on a later pass', async () => {
      const table = buildTable();
      const container = appendTable(table);

      await renderMarkdownTables([table]);
      const renderedTable = findRendered(container);

      expect(renderMarkdownTables([renderedTable])).toBeNull();
      expect(container.querySelectorAll('table')).toHaveLength(1);
      expect(findRendered(container)).toBe(renderedTable);
      expect(
        container.querySelector(
          '[data-testid="table-shadow-overlay"] [data-testid="table-shadow-overlay"]',
        ),
      ).toBeNull();
    });

    describe('when a second copy of the module processes the same container', () => {
      let renderMarkdownTablesCopy;

      beforeEach(() => {
        jest.isolateModules(() => {
          // eslint-disable-next-line global-require
          renderMarkdownTablesCopy = require('~/behaviors/markdown/render_markdown_tables').default;
        });
      });

      it('does not re-mount a table rendered by the first copy', async () => {
        const table = buildTable();
        const container = appendTable(table);

        await renderMarkdownTables([table]);
        const renderedTable = findRendered(container);

        expect(renderMarkdownTablesCopy([renderedTable])).toBeNull();
        expect(container.querySelectorAll('table')).toHaveLength(1);
        expect(findRendered(container)).toBe(renderedTable);
        expect(
          container.querySelector(
            '[data-testid="table-shadow-overlay"] [data-testid="table-shadow-overlay"]',
          ),
        ).toBeNull();
      });

      it('does not mount a table claimed by the first copy while it is still loading', async () => {
        const table = buildTable();
        const container = appendTable(table);

        const rendered = renderMarkdownTables([table]);
        expect(renderMarkdownTablesCopy([table])).toBeNull();

        await rendered;
        await waitForPromises();

        expect(container.querySelectorAll('table')).toHaveLength(1);
      });
    });

    it('does not mount a table claimed by an earlier pass that has yet to finish', async () => {
      const table = buildTable();
      const container = appendTable(table);

      const rendered = renderMarkdownTables([table]);
      expect(renderMarkdownTables([table])).toBeNull();

      await rendered;

      expect(container.querySelectorAll('table')).toHaveLength(1);
    });

    it('does not mount a table without a parent node', () => {
      const table = buildTable();

      expect(renderMarkdownTables([table])).toBeNull();
    });

    it('does not mount a table taken out of the document while loading', async () => {
      const table = buildTable();
      const container = appendTable(table);

      const rendered = renderMarkdownTables([table]);
      table.remove();
      await rendered;

      expect(findRendered(container)).toBeNull();
    });

    describe('with a JSON table', () => {
      it('leaves it to the JSON table renderer', () => {
        const table = buildTable();
        table.dataset.tableFields = '[]';
        const container = appendTable(table);

        expect(renderMarkdownTables([table])).toBeNull();
        expect(container.contains(table)).toBe(true);
        expect(table.dataset.markdownTableApplied).toBeUndefined();
      });
    });

    describe('with a table nested in a cell', () => {
      it('leaves the nested table to the outer one', async () => {
        const nested = createTable({ headers: ['Inner'], rows: [['nested'], ['cells']] });
        const table = createTable({
          rows: [
            [nested, '25'],
            ['Bob', '35'],
          ],
        });
        const container = appendTable(table);

        await renderMarkdownTables([table, nested]);

        const [outer, inner] = container.querySelectorAll('table');
        expect(inner).toBe(nested);
        expect(inner.dataset.markdownTableApplied).toBeUndefined();
        expect(findStickyWrappers(container)).toHaveLength(1);
        expect(outer.tBodies[0].rows).toHaveLength(2);
        expect(inner.tBodies[0].rows).toHaveLength(2);
      });
    });

    describe('when the Markdown itself is rendered inside a table cell', () => {
      it('mounts the table', async () => {
        const table = buildTable();
        const container = appendTable(table);
        const host = document.createElement('table');
        host.insertRow().insertCell().appendChild(container);
        document.body.appendChild(host);

        await renderMarkdownTables([table]);

        expect(findStickyWrappers(container)).toHaveLength(1);
        expect(findSortButtons(container)).toHaveLength(2);
      });
    });
  });

  describe('with a single header row', () => {
    it('mounts inside a sticky-header wrapper', async () => {
      const table = buildTable();
      const container = appendTable(table);

      renderMarkdownTables([table]);
      await waitForPromises();

      const wrapper = container.querySelector('[data-sticky-header]');
      expect(wrapper).not.toBeNull();
      // The component's <table> is a direct child of the wrapper so the
      // existing `[data-sticky-header] > table` CSS applies.
      expect(wrapper.querySelector('table').parentElement).toBe(wrapper);
      expect(wrapper.querySelector('[data-sort-icon]')).not.toBeNull();
    });

    it('replaces the original table with a mounted Vue component', async () => {
      const table = buildTable();
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      expect(container.contains(table)).toBe(false);
      expect(findRendered(container)).not.toBeNull();
    });

    it('leaves the table in place until the component is ready', async () => {
      const table = buildTable();
      const container = appendTable(table);

      const rendered = renderMarkdownTables([table]);
      expect(container.contains(table)).toBe(true);

      await rendered;
      expect(container.contains(table)).toBe(false);
    });

    it('keeps the table footer', async () => {
      const table = buildTable();
      table.appendChild(createSection('tfoot', [createRow('td', ['Average', '30'])]));
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const renderedTable = findRendered(container);
      expect(renderedTable.tFoot).not.toBeNull();
      expect(renderedTable.tFoot.textContent).toContain('Average');
      expect(Array.from(renderedTable.children, (el) => el.tagName)).toEqual([
        'THEAD',
        'TBODY',
        'TFOOT',
      ]);
    });

    it('keeps the table caption', async () => {
      const table = buildTable();
      const caption = document.createElement('caption');
      caption.textContent = 'Team members';
      table.insertBefore(caption, table.firstChild);
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const renderedTable = findRendered(container);
      const renderedCaption = renderedTable.caption;
      expect(renderedCaption).not.toBeNull();
      expect(renderedCaption.textContent).toBe('Team members');
      expect(Array.from(renderedTable.children, (el) => el.tagName)).toEqual([
        'CAPTION',
        'THEAD',
        'TBODY',
      ]);
    });

    describe('cell content', () => {
      it('adopts the original cell elements', async () => {
        const link = document.createElement('a');
        link.href = '/foo';
        link.textContent = 'Alice';

        const table = createTable({ rows: [[link, '25']] });
        const cell = link.parentElement;
        const container = appendTable(table);

        await renderMarkdownTables([table]);

        expect(container.querySelector('tbody td')).toBe(cell);
        expect(container.querySelector('tbody a')).toBe(link);
      });

      it('keeps cell attributes', async () => {
        const table = createTable({ rows: [['Alice', '25']] });
        const cell = table.querySelector('tbody td');
        cell.className = 'task-table-item';
        cell.dataset.sourcepos = '3:2-3:6';
        cell.setAttribute('align', 'right');
        const container = appendTable(table);

        await renderMarkdownTables([table]);

        const rendered = container.querySelector('tbody td');
        expect(rendered.className).toBe('task-table-item');
        expect(rendered.dataset.sourcepos).toBe('3:2-3:6');
        expect(rendered.getAttribute('align')).toBe('right');
      });

      it('carries header cell alignment over to the header we render', async () => {
        const table = buildTable();
        table.querySelectorAll('thead th')[1].setAttribute('align', 'right');
        const container = appendTable(table);

        await renderMarkdownTables([table]);

        const headers = container.querySelectorAll('thead th');
        expect(headers[0].getAttribute('align')).toBeNull();
        expect(headers[1].getAttribute('align')).toBe('right');
      });

      it('keeps work done on the cells before mounting', async () => {
        const link = document.createElement('a');
        link.textContent = 'Alice';
        const table = createTable({ rows: [[link, '25']] });
        const container = appendTable(table);

        const onClick = jest.fn();
        link.addEventListener('click', onClick);
        link.dataset.vivified = 'true';

        await renderMarkdownTables([table]);
        container.querySelector('tbody a').click();

        expect(onClick).toHaveBeenCalled();
        expect(container.querySelector('tbody a').dataset.vivified).toBe('true');
      });

      it('keeps the same cells across a sort', async () => {
        const table = createTable({
          rows: [
            ['Bob', '35'],
            ['Alice', '25'],
          ],
        });
        const [bob] = Array.from(table.querySelectorAll('tbody td'));
        const container = appendTable(table);

        await renderMarkdownTables([table]);
        container.querySelector('thead th button').click();
        await waitForPromises();

        const sorted = Array.from(container.querySelectorAll('tbody td'));
        expect(sorted.map((td) => td.textContent)).toEqual(['Alice', '25', 'Bob', '35']);
        expect(sorted[2]).toBe(bob);
      });
    });
  });

  describe('with a leading header row in the body', () => {
    let container;
    let header;

    beforeEach(async () => {
      header = headerRow();
      const table = buildTableFrom({ bodies: [[header, ...bodyRows()]] });
      container = appendTable(table);

      await renderMarkdownTables([table]);
    });

    it('renders the header row in the table head', () => {
      const rendered = findRendered(container);
      expect(rendered.tHead.rows).toHaveLength(1);
      expect(Array.from(rendered.tHead.rows[0].cells, (cell) => cell.textContent)).toEqual([
        expect.stringContaining('Name'),
        expect.stringContaining('Age'),
      ]);
      expect(cellTexts(rendered.tBodies[0].rows)).toEqual([
        ['Bob', '35'],
        ['Alice', '25'],
      ]);
    });

    it('sorts the body rows', async () => {
      findSortButtons(container)[0].click();
      await waitForPromises();

      expect(cellTexts(findRendered(container).tBodies[0].rows)).toEqual([
        ['Alice', '25'],
        ['Bob', '35'],
      ]);
    });
  });

  describe('with a run of leading header rows in the body', () => {
    it('renders every row in place without sort controls', async () => {
      const headers = [headerRow(), createRow('th', ['First', 'Years'])];
      const headerCells = cellsOf(headers);
      const table = buildTableFrom({ bodies: [[...headers, ...bodyRows()]] });
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const rendered = findRendered(container);
      expect(rendered.tHead).toBeNull();
      expectSameCells(Array.from(rendered.tBodies[0].rows).slice(0, 2), headerCells);
      expect(cellTexts(rendered.tBodies[0].rows)).toEqual([
        ['Name', 'Age'],
        ['First', 'Years'],
        ['Bob', '35'],
        ['Alice', '25'],
      ]);
      expect(findSortButtons(container)).toHaveLength(0);
    });
  });

  describe('with a table head and a leading header row in the body', () => {
    it('renders both header rows in place without sort controls', async () => {
      const table = buildTableFrom({
        head: [headerRow()],
        bodies: [[createRow('th', ['First', 'Years']), ...bodyRows()]],
      });
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const rendered = findRendered(container);
      expect(cellTexts(rendered.tHead.rows)).toEqual([['Name', 'Age']]);
      expect(cellTexts(rendered.tBodies[0].rows)).toEqual([
        ['First', 'Years'],
        ['Bob', '35'],
        ['Alice', '25'],
      ]);
      expect(findSortButtons(container)).toHaveLength(0);
    });
  });

  describe('with multiple header rows in the table head', () => {
    it('renders every header row without sort controls', async () => {
      const head = [headerRow(), createRow('th', ['First', 'Years'])];
      const headCells = cellsOf(head);
      const table = buildTableFrom({ head, bodies: [bodyRows()] });
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const rendered = findRendered(container);
      expectSameCells(rendered.tHead.rows, headCells);
      expect(cellTexts(rendered.tBodies[0].rows)).toEqual([
        ['Bob', '35'],
        ['Alice', '25'],
      ]);
      expect(findSortButtons(container)).toHaveLength(0);
    });
  });

  describe('with multiple bodies', () => {
    it('renders every body in order without sort controls', async () => {
      const table = buildTableFrom({
        head: [headerRow()],
        bodies: [bodyRows(), [createRow('td', ['Carol', '41'])]],
      });
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const rendered = findRendered(container);
      expect(rendered.tBodies).toHaveLength(2);
      expect(cellTexts(rendered.tBodies[0].rows)).toEqual([
        ['Bob', '35'],
        ['Alice', '25'],
      ]);
      expect(cellTexts(rendered.tBodies[1].rows)).toEqual([['Carol', '41']]);
      expect(findSortButtons(container)).toHaveLength(0);
    });
  });

  describe.each`
    section    | attribute
    ${'thead'} | ${'colspan'}
    ${'thead'} | ${'rowspan'}
    ${'tbody'} | ${'colspan'}
    ${'tbody'} | ${'rowspan'}
    ${'tfoot'} | ${'colspan'}
  `('with a $attribute cell in the $section', ({ section, attribute }) => {
    it('renders the table without sort controls', async () => {
      const table = buildTableFrom({
        head: [headerRow()],
        bodies: [bodyRows()],
        foot: [createRow('td', ['Average', '30'])],
      });
      table.querySelector(`${section} td, ${section} th`).setAttribute(attribute, '2');
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      expect(findStickyWrappers(container)).toHaveLength(1);
      expect(findRendered(container).querySelector(`[${attribute}="2"]`)).not.toBeNull();
      expect(findSortButtons(container)).toHaveLength(0);
    });
  });

  describe('without a header row', () => {
    it('mounts the table without a head or sort controls', async () => {
      const rows = [createRow('td', ['Name', 'Age']), ...bodyRows()];
      const rowCells = cellsOf(rows);
      const table = buildTableFrom({ bodies: [rows] });
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const rendered = findRendered(container);
      expect(findStickyWrappers(container)).toHaveLength(1);
      expect(rendered.tHead).toBeNull();
      expectSameCells(rendered.tBodies[0].rows, rowCells);
      expect(rendered.querySelectorAll('th')).toHaveLength(0);
      expect(findSortButtons(container)).toHaveLength(0);
    });
  });

  describe.each([2, 1000])('with %i body rows', (rowCount) => {
    it('renders sort controls', async () => {
      const table = createTable({ rows: Array.from({ length: rowCount }, (_, i) => [`Row ${i}`]) });
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      expect(findSortButtons(container)).toHaveLength(2);
    });
  });

  describe.each([1, 1001])('with %i body rows', (rowCount) => {
    it('mounts the table without sort controls', async () => {
      const table = createTable({ rows: Array.from({ length: rowCount }, (_, i) => [`Row ${i}`]) });
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      expect(findStickyWrappers(container)).toHaveLength(1);
      expect(findRendered(container).tBodies[0].rows).toHaveLength(rowCount);
      expect(findSortButtons(container)).toHaveLength(0);
    });
  });

  describe('with table attributes', () => {
    let container;

    beforeEach(async () => {
      const table = buildTable();
      table.className = 'tableblock stripes-even';
      table.dir = 'auto';
      table.dataset.sourcepos = '1:1-4:9';
      container = appendTable(table);

      await renderMarkdownTables([table]);
    });

    it('keeps them on the rendered table', () => {
      const rendered = findRendered(container);

      expect(rendered.dataset.sourcepos).toBe('1:1-4:9');
      expect(rendered.dataset.markdownTableApplied).toBe('true');
    });

    it('moves the direction to the wrapper', () => {
      expect(findWrapper(container).dir).toBe('auto');
      expect(findRendered(container).hasAttribute('dir')).toBe(false);
    });

    it('merges classes with its own', () => {
      expect(Array.from(findRendered(container).classList)).toEqual(
        expect.arrayContaining(['tableblock', 'stripes-even', 'gl-min-w-full']),
      );
    });
  });

  describe('when the mounted app parent is removed', () => {
    beforeEach(async () => {
      const table = buildTable();
      const container = appendTable(table);

      renderMarkdownTables([table]);
      await waitForPromises();
      container.remove();
      await waitForPromises();
    });

    it('destroys the Vue app', () => {
      expect(mockMarkdownTableDestroyed).toHaveBeenCalledTimes(1);
    });
  });

  describe('when the mounted app is moved within the document', () => {
    beforeEach(async () => {
      const table = buildTable();
      const container = appendTable(table);
      const destination = document.createElement('div');
      document.body.appendChild(destination);

      renderMarkdownTables([table]);
      await waitForPromises();
      destination.appendChild(container.firstElementChild);
      await waitForPromises();
    });

    it('keeps the Vue app mounted', () => {
      expect(mockMarkdownTableDestroyed).not.toHaveBeenCalled();
    });
  });
});
