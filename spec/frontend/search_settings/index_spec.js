import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initSearch from '~/search_settings';
import mount from '~/search_settings/mount';

jest.mock('~/search_settings/mount');

describe('~/search_settings', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  it('initializes search settings when js-search-settings-app is available', async () => {
    setHTMLFixture('<div class="js-search-settings-app"></div>');

    await initSearch();

    expect(mount).toHaveBeenCalled();
  });

  it('does not initialize search settings when js-search-settings-app is unavailable', async () => {
    await initSearch();

    expect(mount).not.toHaveBeenCalled();
  });
});
