import renderMarkdownTables from '~/behaviors/markdown/render_markdown_tables';
import waitForPromises from 'helpers/wait_for_promises';

// Replace the async dynamic import of the component with a synchronous stub so
// the Vue app mounts and renders a <table> during the synchronous test run.
// Without this the dynamic import() never resolves in time and
// `querySelector('table')` returns null (CI: jest / jest vue3).
jest.mock('~/behaviors/components/markdown_table.vue', () => ({
  name: 'MockMarkdownTable',
  props: {
    fields: { type: Array, default: () => [] },
    items: { type: Array, default: () => [] },
    isSortable: { type: Boolean, default: false },
    isSticky: { type: Boolean, default: false },
  },
  render(h) {
    return h('div', { attrs: { 'data-sticky-header': this.isSticky || null } }, [
      h('table', [
        h('thead', [
          h(
            'tr',
            this.fields.map((field) =>
              h('th', { attrs: { 'aria-sort': this.isSortable ? 'none' : null } }, [
                h('span', { domProps: { innerHTML: field.label } }),
              ]),
            ),
          ),
        ]),
        h(
          'tbody',
          this.items.map((item) =>
            h(
              'tr',
              this.fields.map((field) =>
                h('td', [
                  h('span', {
                    domProps: { innerHTML: item[field.key] && item[field.key].html },
                  }),
                ]),
              ),
            ),
          ),
        ),
      ]),
      this.isSortable ? h('span', { attrs: { 'data-sort-icon': '' } }) : null,
    ]);
  },
}));

function createTable({ headers = ['Name', 'Age'], rows = [] } = {}) {
  const table = document.createElement('table');
  const thead = document.createElement('thead');
  const tbody = document.createElement('tbody');
  const headerRow = document.createElement('tr');

  headers.forEach((text) => {
    const th = document.createElement('th');
    th.innerHTML = text;
    headerRow.appendChild(th);
  });
  thead.appendChild(headerRow);

  rows.forEach((rowData) => {
    const tr = document.createElement('tr');
    rowData.forEach((cellData) => {
      const td = document.createElement('td');
      td.innerHTML = cellData;
      tr.appendChild(td);
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
    window.gon = {
      features: { editorStickyTableHeaders: true, markdownSortableTableColumns: true },
    };
  });

  afterEach(() => {
    document.body.innerHTML = '';
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

      renderMarkdownTables([table]);

      expect(container.contains(table)).toBe(true);
    });
  });

  describe('when at least one feature flag is enabled', () => {
    it('replaces the original table with a mounted Vue component', async () => {
      const table = buildTable();
      const container = appendTable(table);

      renderMarkdownTables([table]);
      await waitForPromises();

      expect(container.contains(table)).toBe(false);
      expect(container.querySelector('table')).not.toBeNull();
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
          const td = document.createElement('td');
          td.innerHTML = cell;
          tr.appendChild(td);
        });
        tbody.appendChild(tr);
      });
      table.appendChild(tbody);
      const container = appendTable(table);

      renderMarkdownTables([table]);
      await waitForPromises();

      const headers = Array.from(container.querySelectorAll('thead th')).map(
        (th) => th.textContent,
      );
      expect(headers[0]).toContain('Name');
      expect(headers[1]).toContain('Age');
      expect(container.querySelectorAll('tbody tr')).toHaveLength(2);
    });

    it('preserves rich HTML cell content', async () => {
      const table = createTable({
        rows: [
          ['<a href="/foo">Alice</a>', '25'],
          ['Bob', '35'],
        ],
      });
      const container = appendTable(table);

      renderMarkdownTables([table]);
      await waitForPromises();

      expect(container.querySelector('tbody a')?.getAttribute('href')).toBe('/foo');
    });

    it('processes multiple tables', async () => {
      const table1 = buildTable();
      const table2 = buildTable();
      const container1 = appendTable(table1);
      const container2 = appendTable(table2);

      renderMarkdownTables([table1, table2]);
      await waitForPromises();

      expect(container1.contains(table1)).toBe(false);
      expect(container2.contains(table2)).toBe(false);
      expect(container1.querySelector('table')).not.toBeNull();
      expect(container2.querySelector('table')).not.toBeNull();
    });

    it('does not mount the same table twice', async () => {
      const table = buildTable();
      const container = appendTable(table);

      renderMarkdownTables([table]);
      await waitForPromises();
      const firstTable = container.querySelector('table');

      renderMarkdownTables([table]);

      expect(container.querySelectorAll('table')).toHaveLength(1);
      expect(container.querySelector('table')).toBe(firstTable);
    });

    it('does not mount a table without a parent node', () => {
      const table = buildTable();

      expect(() => renderMarkdownTables([table])).not.toThrow();
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
