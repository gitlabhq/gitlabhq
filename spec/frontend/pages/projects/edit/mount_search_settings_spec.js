import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initSearch from '~/search_settings';
import mountSearchSettings from '~/pages/projects/edit/mount_search_settings';

jest.mock('~/search_settings');

describe('pages/projects/edit/mount_search_settings', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  it('initializes search settings when js-search-settings-app is available', async () => {
    setHTMLFixture('<div class="js-search-settings-app"></div>');

    await mountSearchSettings();

    expect(initSearch).toHaveBeenCalled();
  });

  it('does not initialize search settings when js-search-settings-app is unavailable', async () => {
    await mountSearchSettings();

    expect(initSearch).not.toHaveBeenCalled();
  });
});
