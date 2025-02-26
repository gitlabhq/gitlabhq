import { DiffLineRow } from '~/rapid_diffs/expand_lines/diff_line_row';
import { setHTMLFixture } from 'helpers/fixtures';

describe('DiffLineRow', () => {
  const getRow = () => document.querySelector('tr');

  beforeEach(() => {
    setHTMLFixture(`
      <table>
        <tbody>
          <tr>
            <td>
              <div data-position="old">
                <div data-line-number="3"></div>
              </div>
              <div data-position="new">
                <div data-line-number="4"></div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    `);
  });

  it('#oldLineNumber', () => {
    expect(new DiffLineRow(getRow()).oldLineNumber).toBe(3);
  });

  it('#newLineNumber', () => {
    expect(new DiffLineRow(getRow()).newLineNumber).toBe(4);
  });
});
