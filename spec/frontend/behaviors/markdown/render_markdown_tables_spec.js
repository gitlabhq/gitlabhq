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

function createTable({ headers = ['Name', 'Age'], rows = [] } = {}) {
  const table = document.createElement('table');
  const thead = document.createElement('thead');
  const tbody = document.createElement('tbody');
  const headerRow = document.createElement('tr');

  headers.forEach((content) => {
    headerRow.appendChild(createCell('th', content));
  });
  thead.appendChild(headerRow);

  rows.forEach((rowData) => {
    const tr = document.createElement('tr');
    rowData.forEach((content) => {
      tr.appendChild(createCell('td', content));
    });
    tbody.appendChild(tr);
  });

  table.appendChild(thead);
  table.appendChild(tbody);
  return table;
}

function appendTable(table) {
  const container = document.createElement('div');
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

describe('renderMarkdownTables', () => {
  beforeEach(() => {
    mockMarkdownTableDestroyed.mockClear();
    window.gon = {
      features: { editorStickyTableHeaders: true, markdownSortableTableColumns: true },
    };
  });

  afterEach(async () => {
    document.body.innerHTML = '';
    await waitForPromises();
    delete window.gon;
  });

  describe('when both feature flags are disabled', () => {
    beforeEach(() => {
      window.gon.features.editorStickyTableHeaders = false;
      window.gon.features.markdownSortableTableColumns = false;
    });

    it('leaves the table untouched', () => {
      const table = buildTable();
      const container = appendTable(table);

      expect(renderMarkdownTables([table])).toBeNull();
      expect(container.contains(table)).toBe(true);
    });
  });

  describe('when at least one feature flag is enabled', () => {
    it('replaces the original table with a mounted Vue component', async () => {
      const table = buildTable();
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      expect(container.contains(table)).toBe(false);
      expect(container.querySelector('table')).not.toBeNull();
    });

    it('leaves the table in place until the component is ready', async () => {
      const table = buildTable();
      const container = appendTable(table);

      const rendered = renderMarkdownTables([table]);
      expect(container.contains(table)).toBe(true);

      await rendered;
      expect(container.contains(table)).toBe(false);
    });

    it('uses the first tbody row as the header when there is no thead', async () => {
      const table = document.createElement('table');
      const tbody = document.createElement('tbody');
      [
        ['Name', 'Age'],
        ['Bob', '35'],
        ['Alice', '25'],
      ].forEach((cells) => {
        const tr = document.createElement('tr');
        cells.forEach((cell) => {
          tr.appendChild(createCell('td', cell));
        });
        tbody.appendChild(tr);
      });
      table.appendChild(tbody);
      const container = appendTable(table);

      await renderMarkdownTables([table]);

      const headers = Array.from(container.querySelectorAll('thead th')).map(
        (th) => th.textContent,
      );
      expect(headers[0]).toContain('Name');
      expect(headers[1]).toContain('Age');
      expect(container.querySelectorAll('tbody tr')).toHaveLength(2);
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
        const table = createTable({ rows: [['Alice', '25']] });
        table.querySelectorAll('thead th')[1].setAttribute('align', 'right');
        const container = appendTable(table);

        await renderMarkdownTables([table]);

        const headers = container.querySelectorAll('thead th');
        expect(headers[0].getAttribute('align')).toBeNull();
        expect(headers[1].getAttribute('align')).toBe('right');
      });

      it('leaves a table nested in a cell alone', async () => {
        const nested = createTable({ headers: ['Inner'], rows: [['nested']] });
        const table = createTable({ rows: [[nested, '25']] });
        const container = appendTable(table);

        await renderMarkdownTables([table]);

        const [outer, inner] = container.querySelectorAll('table');
        expect(inner).toBe(nested);
        expect(outer.tBodies[0].rows).toHaveLength(1);
        expect(inner.tHead.rows[0].cells).toHaveLength(1);
        expect(inner.tBodies[0].rows[0].cells).toHaveLength(1);
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
        container.querySelector('thead th').click();
        await waitForPromises();

        const sorted = Array.from(container.querySelectorAll('tbody td'));
        expect(sorted.map((td) => td.textContent)).toEqual(['Alice', '25', 'Bob', '35']);
        expect(sorted[2]).toBe(bob);
      });
    });

    it('processes multiple tables', async () => {
      const table1 = buildTable();
      const table2 = buildTable();
      const container1 = appendTable(table1);
      const container2 = appendTable(table2);

      await renderMarkdownTables([table1, table2]);

      expect(container1.contains(table1)).toBe(false);
      expect(container2.contains(table2)).toBe(false);
      expect(container1.querySelector('table')).not.toBeNull();
      expect(container2.querySelector('table')).not.toBeNull();
    });

    it('does not mount the same table twice', async () => {
      const table = buildTable();
      const container = appendTable(table);

      await renderMarkdownTables([table]);
      const firstTable = container.querySelector('table');

      expect(renderMarkdownTables([table])).toBeNull();
      expect(container.querySelectorAll('table')).toHaveLength(1);
      expect(container.querySelector('table')).toBe(firstTable);
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

      expect(container.querySelector('table')).toBeNull();
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

    describe('sticky headers', () => {
      it('does not add a sticky-header wrapper when sticky is disabled', async () => {
        window.gon.features.editorStickyTableHeaders = false;
        const table = buildTable();
        const container = appendTable(table);

        renderMarkdownTables([table]);
        await waitForPromises();

        expect(container.querySelector('[data-sticky-header]')).toBeNull();
      });

      it('mounts inside a sticky-header wrapper when sticky is enabled', async () => {
        window.gon.features.markdownSortableTableColumns = false;
        const table = buildTable();
        const container = appendTable(table);

        renderMarkdownTables([table]);
        await waitForPromises();

        const wrapper = container.querySelector('[data-sticky-header]');
        expect(wrapper).not.toBeNull();
        // The component's <table> is a direct child of the wrapper so the
        // existing `[data-sticky-header] > table` CSS applies.
        expect(wrapper.querySelector(':scope > table')).not.toBeNull();
        // Sticky-only tables render plain (non-sortable) headers.
        expect(wrapper.querySelector('[data-sort-icon]')).toBeNull();
      });
    });
  });
});
