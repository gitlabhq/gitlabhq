import { createTestingPinia } from '@pinia/testing';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { pinia } from '~/pinia/instance';
import { initNewDiscussionToggle } from '~/rapid_diffs/app/init_new_discussions_toggle';
import { setHTMLFixture } from 'helpers/fixtures';

describe('initNewDiscussionToggle', () => {
  let appElement;
  let toggle;

  const getAppElement = () => document.querySelector('[data-app]');

  const createInlineDiff = () => {
    setHTMLFixture(`
      <div data-app>
        <button data-new-discussion-toggle hidden></button>
        <div data-diffs-list>
          <table>
            <tbody>
              <tr data-hunk-lines>
                <td data-position="new">
                  <a href="/" data-line-number="5"></a>
                </td>
                <td>Diff</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    `);
    appElement = getAppElement();
    toggle = appElement.querySelector('[data-new-discussion-toggle]');
  };

  const createParallelDiff = (hideLineNumber) => {
    const lineNumberHtml = (side) =>
      hideLineNumber === side ? '' : '<a href="/" data-line-number="5"></a>';
    setHTMLFixture(`
      <div data-app>
        <button data-new-discussion-toggle hidden></button>
        <div data-diffs-list>
          <table>
            <tbody data-hunk-lines>
              <tr>
                <td data-position="old">${lineNumberHtml('old')}</td>
                <td data-position="old">Diff</td>
                <td data-position="new">${lineNumberHtml('new')}</td>
                <td data-position="new">Diff</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    `);
    appElement = getAppElement();
    toggle = appElement.querySelector('[data-new-discussion-toggle]');
  };

  beforeEach(() => {
    createTestingPinia();
  });

  describe('inline view', () => {
    beforeEach(() => {
      createInlineDiff();
      initNewDiscussionToggle(appElement);
    });

    it('shows toggle on hover', () => {
      const cell = appElement.querySelector('[data-position]');

      cell.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));

      expect(toggle.hidden).toBe(false);
      expect(toggle.parentElement).toBe(cell);
    });

    it('shows toggle on focus', () => {
      const cell = appElement.querySelector('[data-position]');

      cell.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

      expect(toggle.hidden).toBe(false);
      expect(toggle.parentElement).toBe(cell);
    });

    it('hides toggle when not hovering', () => {
      const cell = appElement.querySelector('[data-position]');

      cell.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
      cell.dispatchEvent(new MouseEvent('mouseout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(true);
    });

    it('hides toggle when not in focus', () => {
      const cell = appElement.querySelector('[data-position]');

      cell.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));
      cell.dispatchEvent(new FocusEvent('focusout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(true);
    });

    it('restores toggle on focused cell after mouseout', () => {
      const cell = appElement.querySelector('[data-position]');
      const lineNumber = cell.querySelector('[data-line-number]');

      lineNumber.dispatchEvent(new FocusEvent('focusin', { bubbles: true, target: lineNumber }));
      expect(toggle.hidden).toBe(false);

      cell.dispatchEvent(new MouseEvent('mouseout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(false);
      expect(toggle.parentElement).toBe(cell);
    });

    it('hides toggle after mouseout when focus moves to toggle itself', () => {
      const cell = appElement.querySelector('[data-position]');

      cell.dispatchEvent(new FocusEvent('focusin', { bubbles: true, target: cell }));
      expect(toggle.hidden).toBe(false);

      toggle.dispatchEvent(new FocusEvent('focusin', { bubbles: true, target: toggle }));
      cell.dispatchEvent(new FocusEvent('focusout', { bubbles: true, target: cell }));
      cell.dispatchEvent(new MouseEvent('mouseout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(true);
    });
  });

  describe('parallel view', () => {
    it.each(['old', 'new'])(
      'shows toggle on hover for %s side when line number is present',
      (side) => {
        createParallelDiff();
        initNewDiscussionToggle(appElement);

        const cell = appElement.querySelector(`[data-position="${side}"]`);
        cell.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));

        expect(toggle.hidden).toBe(false);
        expect(toggle.parentElement).toBe(cell);
      },
    );

    it.each(['old', 'new'])(
      'hides toggle on hover for %s side when line number is not present',
      (side) => {
        createParallelDiff(side);
        initNewDiscussionToggle(appElement);

        const cell = appElement.querySelector(`[data-position="${side}"]`);
        cell.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));

        expect(toggle.hidden).toBe(true);
      },
    );

    it('shows toggle on focus', () => {
      createParallelDiff();
      initNewDiscussionToggle(appElement);

      const cell = appElement.querySelector('[data-position="new"]');
      cell.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

      expect(toggle.hidden).toBe(false);
    });

    it('hides toggle when not hovering', () => {
      createParallelDiff();
      initNewDiscussionToggle(appElement);

      const cell = appElement.querySelector('[data-position="new"]');
      cell.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
      cell.dispatchEvent(new MouseEvent('mouseout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(true);
    });

    it('hides toggle when not in focus', () => {
      createParallelDiff();
      initNewDiscussionToggle(appElement);

      const cell = appElement.querySelector('[data-position="new"]');
      cell.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));
      cell.dispatchEvent(new FocusEvent('focusout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(true);
    });

    it('hides toggle when line number is not present', () => {
      createParallelDiff('new');
      initNewDiscussionToggle(appElement);

      const cell = appElement.querySelector('[data-position="new"]');
      cell.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));

      expect(toggle.hidden).toBe(true);
    });

    it('restores toggle on focused cell after mouseout', () => {
      createParallelDiff();
      initNewDiscussionToggle(appElement);

      const cell = appElement.querySelector('[data-position="new"]');
      const lineNumber = cell.querySelector('[data-line-number]');

      lineNumber.dispatchEvent(new FocusEvent('focusin', { bubbles: true, target: lineNumber }));
      expect(toggle.hidden).toBe(false);

      cell.dispatchEvent(new MouseEvent('mouseout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(false);
      expect(toggle.parentElement).toBe(cell);
    });

    it('hides toggle after mouseout when focus moves to toggle itself', () => {
      createParallelDiff();
      initNewDiscussionToggle(appElement);

      const cell = appElement.querySelector('[data-position="new"]');

      cell.dispatchEvent(new FocusEvent('focusin', { bubbles: true, target: cell }));
      expect(toggle.hidden).toBe(false);

      toggle.dispatchEvent(new FocusEvent('focusin', { bubbles: true, target: toggle }));
      cell.dispatchEvent(new FocusEvent('focusout', { bubbles: true, target: cell }));
      cell.dispatchEvent(new MouseEvent('mouseout', { bubbles: true }));
      jest.runAllTimers();

      expect(toggle.hidden).toBe(true);
    });
  });

  it('moves toggle element outside of diffs list when reloadDiffs action is triggered', () => {
    createInlineDiff();
    initNewDiscussionToggle(appElement);

    const diffsListParent = appElement.querySelector('[data-diffs-list]').parentElement;
    useDiffsList(pinia).reloadDiffs();

    expect(toggle.parentElement).toBe(diffsListParent);
  });
});
