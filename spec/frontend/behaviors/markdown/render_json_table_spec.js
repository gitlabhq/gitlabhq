import { nextTick } from 'vue';
import { renderJSONTable } from '~/behaviors/markdown/render_json_table';

describe('behaviors/markdown/render_json_table', () => {
  let element;

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

  const tableAsData = (table) => ({
    head: Array.from(table.querySelectorAll('thead th')).map((td) => td.textContent),
    body: Array.from(table.querySelectorAll('tbody > tr')).map((tr) =>
      Array.from(tr.querySelectorAll('td')).map((x) => x.textContent),
    ),
  });

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

  const findPres = () => document.querySelectorAll('pre');
  const findTables = () => document.querySelectorAll('table');
  const findAlerts = () => document.querySelectorAll('.gl-alert');
  const findInputs = () => document.querySelectorAll('.gl-form-input');

  afterEach(() => {
    document.body.innerHTML = '';
    element = null;
  });

  describe('default', () => {
    beforeEach(async () => {
      await createTestSubject(JSON.stringify(TEST_DATA, null, 2));
    });

    it('removes pre', () => {
      expect(findPres()).toHaveLength(0);
    });

    it('replaces pre with table', () => {
      const tables = findTables();

      expect(tables).toHaveLength(1);
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
