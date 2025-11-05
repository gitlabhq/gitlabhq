import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import initSettingsPanels from '~/settings_panels';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import SearchBox from '~/pages/experimental/o11y_service_settings/search_box.vue';

jest.mock('~/settings_panels');
jest.mock('~/helpers/init_simple_app_helper', () => ({
  initSimpleApp: jest.fn(),
}));

describe('experimental/o11y_service_settings/index', () => {
  const mountSelector = '#js-o11y-service-settings-search';

  beforeEach(() => {
    jest.clearAllMocks();
    setHTMLFixture(`<div id="${mountSelector.replace('#', '')}"></div>`);
  });

  afterEach(() => {
    resetHTMLFixture();
    jest.resetModules();
  });

  it('calls initSettingsPanels and initSimpleApp on DOMContentLoaded', async () => {
    Object.defineProperty(document, 'readyState', {
      writable: true,
      value: 'loading',
    });

    await import('~/pages/experimental/o11y_service_settings/index');

    const event = new Event('DOMContentLoaded');
    document.dispatchEvent(event);

    await waitForPromises();

    expect(initSettingsPanels).toHaveBeenCalled();
    expect(initSimpleApp).toHaveBeenCalledWith(mountSelector, SearchBox, {
      name: 'O11yServiceSettingsSearch',
    });

    Object.defineProperty(document, 'readyState', {
      writable: true,
      value: 'complete',
    });
  });
});
