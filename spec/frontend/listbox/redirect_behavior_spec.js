import { initListbox } from '~/listbox';
import { initRedirectListboxBehavior } from '~/listbox/redirect_behavior';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { getFixture, setHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/listbox', () => ({
  initListbox: jest.fn().mockReturnValue({ foo: true }),
}));

const fixture = getFixture('listbox/redirect_listbox.html');

describe('initRedirectListboxBehavior', () => {
  let instances;

  beforeEach(() => {
    setHTMLFixture(`
      ${fixture}
      ${fixture}
    `);

    instances = initRedirectListboxBehavior();
  });

  it('calls initListbox for each .js-redirect-listbox', () => {
    expect(instances).toEqual([{ foo: true }, { foo: true }]);

    expect(initListbox).toHaveBeenCalledTimes(2);

    initListbox.mock.calls.forEach((callArgs, i) => {
      const elements = document.querySelectorAll('.js-redirect-listbox');

      expect(callArgs[0]).toBe(elements[i]);
      expect(callArgs[1]).toEqual({
        onChange: expect.any(Function),
      });
    });
  });

  it('passes onChange handler to initListbox that calls redirectTo', () => {
    const [firstCallArgs] = initListbox.mock.calls;
    const { onChange } = firstCallArgs[1];
    const mockItem = { href: '/foo' };

    expect(redirectTo).not.toHaveBeenCalled(); // eslint-disable-line import/no-deprecated

    onChange(mockItem);

    expect(redirectTo).toHaveBeenCalledWith(mockItem.href); // eslint-disable-line import/no-deprecated
  });
});
