import { ExpandLinesAdapter } from '~/rapid_diffs/expand_lines/adapter';
import { setHTMLFixture } from 'helpers/fixtures';
import { getLines } from '~/rapid_diffs/expand_lines/get_lines';
import { DiffLineRow } from '~/rapid_diffs/expand_lines/diff_line_row';

jest.mock('~/rapid_diffs/expand_lines/get_lines');

describe('ExpandLinesAdapter', () => {
  const getExpandButton = () => document.querySelector('[data-click="expandLines"]');
  const getResultingHtml = () => document.querySelector('#response');
  const getSurroundingLines = () => [
    new DiffLineRow(document.querySelector('[data-hunk-lines="1"]')),
    new DiffLineRow(document.querySelector('[data-hunk-lines="2"]')),
  ];
  const getDiffFileContext = () => {
    return { data: { diffLinesPath: '/lines' }, viewer: 'text_parallel' };
  };

  beforeEach(() => {
    setHTMLFixture(`
      <table>
        <tbody>
          <tr data-hunk-lines="1">
            <td>
            </td>
          </tr>
          <tr>
            <td>
              <button data-click="expandLines" data-expand-direction="up"></button>
            </td>
          </tr>
          <tr data-hunk-lines="2">
            <td>
            </td>
          </tr>
        </tbody>
      </table>
    `);
  });

  it('expands lines', async () => {
    getLines.mockResolvedValueOnce('<div id="response"></div>');
    await ExpandLinesAdapter.clicks.expandLines.call(
      getDiffFileContext(),
      new MouseEvent('click'),
      getExpandButton(),
    );
    expect(getLines).toHaveBeenCalledWith({
      expandDirection: 'up',
      surroundingLines: getSurroundingLines(),
      diffLinesPath: '/lines',
      view: 'parallel',
    });
    expect(getResultingHtml()).not.toBe(null);
    expect(getExpandButton()).toBe(null);
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
    ExpandLinesAdapter.clicks.expandLines.call(
      getDiffFileContext(),
      new MouseEvent('click'),
      getExpandButton(),
    );
    ExpandLinesAdapter.clicks.expandLines.call(
      getDiffFileContext(),
      new MouseEvent('click'),
      getExpandButton(),
    );
    expect(getLines).toHaveBeenCalledTimes(1);
    res();
  });
});
