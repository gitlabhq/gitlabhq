import { expandLinesAdapter } from '~/rapid_diffs/adapters/expand_lines';
import { setHTMLFixture } from 'helpers/fixtures';
import { getLines } from '~/rapid_diffs/adapters/expand_lines/get_lines';
import { DiffLineRow } from '~/rapid_diffs/adapters/expand_lines/diff_line_row';
import { createAlert } from '~/alert';

jest.mock('~/alert');
jest.mock('~/rapid_diffs/adapters/expand_lines/get_lines');

describe('expandLinesAdapter', () => {
  const getExpandButton = (direction = 'up') =>
    document.querySelector(`[data-expand-direction="${direction}"]`);
  const getFirstInsertedRow = () => document.querySelector('[data-hunk-lines="3"]');
  const getLastInsertedRow = () => document.querySelector('[data-hunk-lines="4"]');
  const getDiffElement = () => document.querySelector('#diffElement');
  const getSurroundingLines = (direction) => {
    const prev = getExpandButton(direction).closest('tr').previousElementSibling;
    const next = getExpandButton(direction).closest('tr').nextElementSibling;
    return [prev ? new DiffLineRow(prev) : null, next ? new DiffLineRow(next) : null];
  };
  const getDiffFileContext = () => {
    return {
      data: { diffLinesPath: '/lines', viewer: 'text_parallel' },
      diffElement: getDiffElement(),
    };
  };
  const click = (direction) => {
    return expandLinesAdapter.clicks.expandLines.call(
      getDiffFileContext(),
      new MouseEvent('click'),
      getExpandButton(direction),
    );
  };
  // tabindex="0" makes document.activeElement actually work in JSDOM
  const createLinesResponse = () =>
    `
      <tr data-hunk-lines="3"><td><a data-line-number="5" tabindex="0"></a></td></tr>
      <tr data-hunk-lines="4"><td><a data-line-number="6" tabindex="0"></a></td></tr>
    `.trim();

  beforeEach(() => {
    setHTMLFixture(`
      <div id="diffElement">
        <div data-file-body>
          <table>
            <tbody>
              <tr>
                <td>
                  <button data-click="expandLines" data-expand-direction="up"></button>
                </td>
              </tr>
              <tr data-hunk-lines="1">
                <td>
                </td>
              </tr>
              <tr>
                <td>
                  <button data-click="expandLines" data-expand-direction="both"></button>
                </td>
              </tr>
              <tr data-hunk-lines="2">
                <td>
                </td>
              </tr>
              <tr>
                <td>
                  <button data-click="expandLines" data-expand-direction="down"></button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    `);
  });

  it.each(['up', 'both', 'down'])('expands lines in %s direction(s)', async (direction) => {
    getLines.mockResolvedValueOnce(createLinesResponse());
    const surroundingLines = getSurroundingLines(direction);
    await click(direction);
    expect(getLines).toHaveBeenCalledWith({
      expandDirection: direction,
      surroundingLines,
      diffLinesPath: '/lines',
      view: 'parallel',
    });
    expect(getFirstInsertedRow()).not.toBe(null);
    expect(getLastInsertedRow()).not.toBe(null);
    expect(getExpandButton(direction)).toBe(null);
    expect(getDiffElement().style.getPropertyValue('--total-rows')).toBe('6');
  });

  it('focuses first inserted line number', async () => {
    getLines.mockResolvedValueOnce(createLinesResponse());
    await click('down');
    expect(document.activeElement).toEqual(
      getFirstInsertedRow().querySelector('[data-line-number]'),
    );
  });

  it('focuses last inserted line number', async () => {
    getLines.mockResolvedValueOnce(createLinesResponse());
    await click();
    expect(document.activeElement).toEqual(
      getLastInsertedRow().querySelector('[data-line-number]'),
    );
  });

  it('prevents expansion while processing another expansion', () => {
    let res;
    getLines.mockImplementation(
      jest.fn(
        () =>
          new Promise((resolve) => {
            res = resolve;
          }),
      ),
    );
    click();
    click();
    expect(getLines).toHaveBeenCalledTimes(1);
    res(createLinesResponse());
  });

  it('handles lines fetching error', async () => {
    const error = new Error();
    getLines.mockRejectedValue(error);
    await click();
    expect(createAlert).toHaveBeenCalledWith({
      message: 'Failed to expand lines, please try again.',
      error,
    });
    expect(getExpandButton().closest('tr').dataset.loading).toBe(undefined);
    expect(getExpandButton().disabled).toBe(false);
  });
});
