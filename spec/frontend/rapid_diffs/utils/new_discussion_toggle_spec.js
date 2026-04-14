import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { moveToggle } from '~/rapid_diffs/utils/new_discussion_toggle';

describe('moveToggle', () => {
  let toggle;

  const inlineRow = () =>
    `<tr>
      <td data-position="old"><a data-line-number="1"></a></td>
      <td data-position="new"><a data-line-number="1"></a></td>
    </tr>`;

  const parallelRow = () =>
    `<tr>
      <td data-position="old"><a data-line-number="1"></a></td>
      <td data-position="old"></td>
      <td data-position="new"><a data-line-number="1"></a></td>
      <td data-position="new"></td>
    </tr>`;

  beforeEach(() => {
    setHTMLFixture(`
      <table><tbody>
        <tr id="previous-row" data-has-new-discussion-toggle>
          <td data-position="old"></td>
          <td data-position="new"></td>
        </tr>
      </tbody></table>
    `);
    toggle = document.createElement('button');
    document.querySelector('#previous-row td').prepend(toggle);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('removes data-has-new-discussion-toggle from the previous row', () => {
    setHTMLFixture(`<table><tbody>${inlineRow()}</tbody></table>`);
    toggle = document.createElement('button');
    const previousRow = document.createElement('tr');
    previousRow.dataset.hasNewDiscussionToggle = '';
    previousRow.appendChild(document.createElement('td')).prepend(toggle);
    document.querySelector('tbody').prepend(previousRow);

    const row = document.querySelector('tr:last-child');
    moveToggle(toggle, row, undefined);

    expect(previousRow.dataset.hasNewDiscussionToggle).toBeUndefined();
  });

  it('sets data-has-new-discussion-toggle on the new row', () => {
    const row = document.querySelector('tr');
    moveToggle(toggle, row, undefined);

    expect(row.dataset.hasNewDiscussionToggle).toBeDefined();
  });

  describe('inline view', () => {
    beforeEach(() => {
      setHTMLFixture(`<table><tbody>${inlineRow()}</tbody></table>`);
      toggle = document.createElement('button');
    });

    it('prepends toggle to the first [data-position] cell', () => {
      const row = document.querySelector('tr');
      moveToggle(toggle, row, undefined);

      expect(row.querySelector('[data-position="old"]').firstChild).toBe(toggle);
    });

    it('ignores side parameter and always uses first cell', () => {
      const row = document.querySelector('tr');
      moveToggle(toggle, row, 'new');

      expect(row.querySelector('[data-position="old"]').firstChild).toBe(toggle);
    });
  });

  describe('parallel view', () => {
    beforeEach(() => {
      setHTMLFixture(`<table><tbody>${parallelRow()}</tbody></table>`);
      toggle = document.createElement('button');
    });

    it('prepends toggle to the old side cell', () => {
      const row = document.querySelector('tr');
      moveToggle(toggle, row, 'old');

      expect(row.querySelector('[data-position="old"]').firstChild).toBe(toggle);
    });

    it('prepends toggle to the new side cell', () => {
      const row = document.querySelector('tr');
      moveToggle(toggle, row, 'new');

      expect(row.querySelector('[data-position="new"]').firstChild).toBe(toggle);
    });
  });
});
