import findAndFollowLink from '~/lib/utils/navigation_utility';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

describe('findAndFollowLink', () => {
  it('visits a link when the selector exists', () => {
    const href = '/some/path';

    setFixtures(`<a class="my-shortcut" href="${href}">link</a>`);

    findAndFollowLink('.my-shortcut');

    expect(visitUrl).toHaveBeenCalledWith(href);
  });

  it('does not throw an exception when the selector does not exist', () => {
    // this should not throw an exception
    findAndFollowLink('.this-selector-does-not-exist');

    expect(visitUrl).not.toHaveBeenCalled();
  });
});
