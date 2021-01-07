import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initSearch from '~/search_settings';
import mountSearchSettings from '~/pages/projects/edit/mount_search_settings';

jest.mock('~/search_settings');

describe('pages/projects/edit/mount_search_settings', () => {
  afterEach(() => {
    initSearch.mockReset();
    resetHTMLFixture();
  });

  it('initializes search settings when js-search-settings-app is available', async () => {
    setHTMLFixture('<div class="js-search-settings-app"></div>');

    mountSearchSettings();

    await waitForPromises();

    expect(initSearch).toHaveBeenCalled();
  });

  it('does not initialize search settings when js-search-settings-app is unavailable', async () => {
    mountSearchSettings();

    await waitForPromises();

    expect(initSearch).not.toHaveBeenCalled();
  });
});
