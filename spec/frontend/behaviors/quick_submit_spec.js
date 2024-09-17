import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initQuickSubmit } from '~/behaviors/quick_submit';
import { ENTER_KEY } from '~/lib/utils/keys';

describe('Quick Submit behavior', () => {
  let buttonSpy;

  const findButton = () => document.querySelector('button');
  const findForm = () => document.querySelector('form');

  beforeEach(() => {
    setHTMLFixture(`
      <form action="/foo" class="js-quick-submit">
        <input type="text" />
        <textarea></textarea>
        <button type="submit" value="Submit" />
      </form>
    `);
    initQuickSubmit();
    buttonSpy = jest.spyOn(findButton(), 'click').mockImplementation(() => {});
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('submits form with Ctrl+Enter', () => {
    findForm().dispatchEvent(new KeyboardEvent('keydown', { code: ENTER_KEY, ctrlKey: true }));

    expect(buttonSpy).toHaveBeenCalled();
  });

  it('submits form with Cmd+Enter', () => {
    findForm().dispatchEvent(new KeyboardEvent('keydown', { code: ENTER_KEY, metaKey: true }));

    expect(buttonSpy).toHaveBeenCalled();
  });

  it('does not submit form with Alt+Enter', () => {
    findForm().dispatchEvent(new KeyboardEvent('keydown', { code: ENTER_KEY, altKey: true }));

    expect(buttonSpy).not.toHaveBeenCalled();
  });

  it('does not submit form with Shift+Enter', () => {
    findForm().dispatchEvent(new KeyboardEvent('keydown', { code: ENTER_KEY, shiftKey: true }));

    expect(buttonSpy).not.toHaveBeenCalled();
  });

  it('does not submit form with only Enter', () => {
    findForm().dispatchEvent(new KeyboardEvent('keydown', { code: ENTER_KEY }));

    expect(buttonSpy).not.toHaveBeenCalled();
  });

  it('disables button after form submission', () => {
    expect(findButton().disabled).toBe(false);

    findForm().dispatchEvent(new KeyboardEvent('keydown', { code: ENTER_KEY, metaKey: true }));

    expect(findButton().disabled).toBe(true);
  });
});
