import htmlRedirectListbox from 'test_fixtures/listbox/redirect_listbox.html';
import { initListbox } from '~/listbox';
import { initRedirectListboxBehavior } from '~/listbox/redirect_behavior';
import { visitUrl } from '~/lib/utils/url_utility';
import { setHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/listbox', () => ({
  initListbox: jest.fn().mockReturnValue({ foo: true }),
}));

describe('initRedirectListboxBehavior', () => {
  let instances;

  beforeEach(() => {
    setHTMLFixture(`
      ${htmlRedirectListbox}
      ${htmlRedirectListbox}
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

  it('passes onChange handler to initListbox that calls visitUrl', () => {
    const [firstCallArgs] = initListbox.mock.calls;
    const { onChange } = firstCallArgs[1];
    const mockItem = { href: '/foo' };

    expect(visitUrl).not.toHaveBeenCalled();

    onChange(mockItem);

    expect(visitUrl).toHaveBeenCalledWith(mockItem.href);
  });
});
