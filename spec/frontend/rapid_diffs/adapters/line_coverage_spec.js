import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { EXPANDED_LINES } from '~/rapid_diffs/adapter_events';
import { lineCoverageAdapter } from '~/rapid_diffs/adapters/line_coverage';
import { useTestCoverage } from '~/rapid_diffs/stores/test_coverage';
import { pinia } from '~/pinia/instance';

jest.mock('~/pinia/instance', () => {
  // eslint-disable-next-line global-require
  const { createPinia, setActivePinia } = require('pinia');
  const instance = createPinia();
  setActivePinia(instance);
  return { pinia: instance };
});

const newPath = 'app/foo.rb';

describe('lineCoverageAdapter', () => {
  let store;

  const setupFixture = ({ filePath = newPath } = {}) => {
    const fileData = { viewer: 'text_inline', oldPath: newPath, newPath: filePath };
    setHTMLFixture(`
      <diff-file id="abc" data-file-data='${JSON.stringify(fileData)}'>
        <div>
          <table>
            <tbody>
              <tr data-hunk-lines>
                <td data-position="old"></td>
                <td data-position="new"></td>
                <td data-position="new" class="rd-line-content">
                  <span data-line-coverage="5"></span>
                  <pre class="rd-line-text"></pre>
                </td>
              </tr>
              <tr data-hunk-lines>
                <td data-position="old"></td>
                <td data-position="new"></td>
                <td data-position="new" class="rd-line-content">
                  <span data-line-coverage="6"></span>
                  <pre class="rd-line-text"></pre>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </diff-file>
    `);
  };

  const mountWithAdapter = () => {
    document.querySelector('diff-file').mount({
      adapterConfig: { text_inline: [lineCoverageAdapter] },
      appData: {},
      observe: jest.fn(),
      unobserve: jest.fn(),
    });
  };

  const getSlots = () => document.querySelectorAll('[data-line-coverage]');

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    store = useTestCoverage(pinia);
    store.$reset();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('does nothing when coverage data has not loaded', () => {
    setupFixture();
    mountWithAdapter();
    getSlots().forEach((slot) => {
      expect(slot.dataset.coverage).toBeUndefined();
      expect(slot.title).toBe('');
    });
  });

  it('decorates slots with hit and miss states once coverage is loaded', async () => {
    setupFixture();
    mountWithAdapter();

    store.files = { [newPath]: { 5: 3, 6: 0 } };
    store.loaded = true;
    await Promise.resolve();

    const [slot5, slot6] = getSlots();
    expect(slot5.dataset.coverage).toBe('hit');
    expect(slot5.title).toBe('Test coverage: 3 hits');
    expect(slot6.dataset.coverage).toBe('miss');
    expect(slot6.title).toBe('No test coverage');
  });

  it('leaves slots without coverage data undecorated', async () => {
    setupFixture();
    mountWithAdapter();

    store.files = { [newPath]: { 5: 1 } };
    store.loaded = true;
    await Promise.resolve();

    const [slot5, slot6] = getSlots();
    expect(slot5.dataset.coverage).toBe('hit');
    expect(slot6.dataset.coverage).toBeUndefined();
    expect(slot6.title).toBe('');
  });

  it('re-decorates on EXPANDED_LINES', async () => {
    setupFixture();
    mountWithAdapter();

    store.files = { [newPath]: { 5: 1 } };
    store.loaded = true;
    await Promise.resolve();

    const newRow = document.createElement('tr');
    newRow.dataset.hunkLines = '';
    newRow.innerHTML = `
      <td data-position="old"></td>
      <td data-position="new"></td>
      <td data-position="new" class="rd-line-content">
        <span data-line-coverage="7"></span>
        <pre class="rd-line-text"></pre>
      </td>
    `;
    document.querySelector('tbody').appendChild(newRow);
    store.files = { [newPath]: { 5: 1, 7: 0 } };
    document.querySelector('diff-file').trigger(EXPANDED_LINES);

    const slot7 = document.querySelector('[data-line-coverage="7"]');
    expect(slot7.dataset.coverage).toBe('miss');
  });

  it('does nothing when the file has no newPath', () => {
    setupFixture({ filePath: '' });
    mountWithAdapter();

    store.files = { '': { 5: 3 } };
    store.loaded = true;

    getSlots().forEach((slot) => {
      expect(slot.dataset.coverage).toBeUndefined();
    });
  });
});
