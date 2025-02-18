import { nextTick } from 'vue';
import { renderJSONTable, renderJSONTableHTML } from '~/behaviors/markdown/render_json_table';

describe('behaviors/markdown/render_json_table', () => {
  let element;

  const tableAsData = (table) => ({
    head: Array.from(table.querySelectorAll('thead th')).map((td) => td.textContent.trim()),
    body: Array.from(table.querySelectorAll('tbody > tr')).map((tr) =>
      Array.from(tr.querySelectorAll('td')).map((x) => x.innerHTML),
    ),
  });

  const findPres = () => document.querySelectorAll('pre');
  const findTables = () => document.querySelectorAll('table');
  const findAlerts = () => document.querySelectorAll('.gl-alert');
  const findInputs = () => document.querySelectorAll('.gl-form-input');
  const findCaption = () => document.querySelector('caption');
  const findJsonTables = () => document.querySelectorAll('.js-json-table');

  afterEach(() => {
    document.body.innerHTML = '';
    element = null;
  });

  describe('standard JSON table', () => {
    const TEST_DATA = {
      fields: [
        { label: 'Field 1', key: 'a' },
        { label: 'F 2', key: 'b' },
        { label: 'F 3', key: 'c' },
      ],
      items: [
        {
          a: '1',
          b: 'b',
          c: 'c',
        },
        {
          a: '2',
          b: 'd',
          c: 'e',
        },
      ],
    };
    const TEST_LABELS = TEST_DATA.fields.map((x) => x.label);

    const createTestSubject = async (json) => {
      if (element) {
        throw new Error('element has already been initialized');
      }

      const parent = document.createElement('div');
      const pre = document.createElement('pre');

      pre.textContent = json;
      parent.appendChild(pre);

      document.body.appendChild(parent);
      renderJSONTable([parent]);

      element = parent;

      jest.runAllTimers();

      await nextTick();
    };

    describe('default', () => {
      beforeEach(async () => {
        await createTestSubject(JSON.stringify(TEST_DATA, null, 2));
      });

      it('removes pre', () => {
        expect(findPres()).toHaveLength(0);
      });

      it('replaces pre with table', () => {
        const tables = findTables();
        const jsonTables = findJsonTables();

        expect(tables).toHaveLength(1);
        expect(jsonTables).toHaveLength(1);
        expect(tableAsData(tables[0])).toEqual({
          head: TEST_LABELS,
          body: [
            ['1', 'b', 'c'],
            ['2', 'd', 'e'],
          ],
        });
      });

      it('does not show filter', () => {
        expect(findInputs()).toHaveLength(0);
      });
    });

    describe('with invalid json', () => {
      beforeEach(() => {
        createTestSubject('funky but not json');
      });

      it('preserves pre', () => {
        expect(findPres()).toHaveLength(1);
      });

      it('shows alert', () => {
        const alerts = findAlerts();

        expect(alerts).toHaveLength(1);
        expect(alerts[0].textContent).toMatchInterpolatedText('Unable to parse JSON');
      });
    });

    describe('with filter set', () => {
      beforeEach(() => {
        createTestSubject(JSON.stringify({ ...TEST_DATA, filter: true }));
      });

      it('shows filter', () => {
        expect(findInputs()).toHaveLength(1);
      });
    });
  });

  describe('markdown JSON table', () => {
    const TEST_MARKDOWN_DATA = `
      <table data-table-fields='[{"key":"starts_at","label":"Date \\u003c \\u0026 \\u003e","sortable":false},{"key":"url","label":"URL"}]' data-table-filter="false" data-table-markdown="true">
      <caption><p>Markdown <em>enabled</em> table</p></caption>
      <thead>
      <tr>
      <th>Date &lt; &amp; &gt;</th>
      <th>URL</th>
      </tr>
      </thead>
      <tbody>
      <tr>
      <td><em>2024-10-07</em></td>
      <td></td>
      </tr>
      <tr>
      <td></td>
      <td><a href="https://example.com/page2.html">https://example.com/page2.html</a></td>
      </tr>
      </tbody>
      </table>
    `;

    const TEST_MARKDOWN_INVALID_DATA = `
      <table data-table-fields='[{"key""starts_at","label":"Date"}]' data-table-filter="false" data-table-markdown="true">
      <caption><p>Markdown <em>enabled</em> table</p></caption>
      <thead>
      <tr><th>Date</th></tr>
      </thead>
      <tbody>
      <tr><td><em>2024-10-07</em></td></tr>
      </tbody>
      </table>
    `;

    const TEST_MARKDOWN_FILTERABLE_DATA = `
      <table data-table-fields='[{"key":"starts_at","label":"Date"}]' data-table-filter="true" data-table-markdown="true">
      <caption>foo</caption>
      <thead>
      <tr><th>Date</th></tr>
      </thead>
      <tbody>
      <tr><td>bar</td></tr>
      </tbody>
      </table>
    `;

    const createTestSubject = async (html) => {
      if (element) {
        throw new Error('element has already been initialized');
      }

      const parent = document.createElement('div');
      parent.innerHTML = html;

      document.body.appendChild(parent);
      renderJSONTableHTML([parent.firstElementChild]);

      element = parent;

      jest.runAllTimers();

      await nextTick();
    };

    describe('default', () => {
      beforeEach(async () => {
        await createTestSubject(TEST_MARKDOWN_DATA);
      });

      it('handles existing table with embedded HTML', () => {
        const tables = findTables();
        const jsonTables = findJsonTables();

        expect(tables).toHaveLength(1);
        expect(jsonTables).toHaveLength(1);
        expect(tableAsData(tables[0])).toEqual({
          head: ['Date < & >', 'URL'],
          body: [
            ['<div><em>2024-10-07</em></div>', '<div></div>'],
            [
              '<div></div>',
              '<div><a href="https://example.com/page2.html">https://example.com/page2.html</a></div>',
            ],
          ],
        });
      });

      it('caption is allowed HTML', () => {
        const caption = findCaption().innerHTML;

        expect(caption).toEqual('<small>Markdown <em>enabled</em> table</small>');
      });

      it('does not show filter', () => {
        expect(findInputs()).toHaveLength(0);
      });
    });

    describe('with invalid data-table-fields json', () => {
      beforeEach(() => {
        createTestSubject(TEST_MARKDOWN_INVALID_DATA);
      });

      it('shows alert', () => {
        const alerts = findAlerts();

        expect(alerts).toHaveLength(1);
        expect(alerts[0].textContent).toMatchInterpolatedText('Unable to parse JSON');
      });
    });

    describe('with filter set', () => {
      beforeEach(() => {
        createTestSubject(TEST_MARKDOWN_FILTERABLE_DATA);
      });

      it('shows filter', () => {
        expect(findInputs()).toHaveLength(1);
      });
    });
  });
});
