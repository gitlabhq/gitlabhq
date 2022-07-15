import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import initHeaderSearch, { eventHandler } from '~/header_search/init';

describe('Header Search EventListener', () => {
  beforeEach(() => {
    jest.resetModules();
    jest.restoreAllMocks();
    setHTMLFixture(`
      <div class="js-header-content">
        <div class="header-search" id="js-header-search" data-autocomplete-path="/search/autocomplete" data-issues-path="/dashboard/issues" data-mr-path="/dashboard/merge_requests" data-search-context="{}" data-search-path="/search">
          <input autocomplete="off" class="form-control gl-form-input gl-search-box-by-type-input" data-qa-selector="search_box" id="search" name="search" placeholder="Search GitLab" type="text">
        </div>
      </div>`);
  });

  afterEach(() => {
    resetHTMLFixture();
    jest.clearAllMocks();
  });

  it('attached event listener', () => {
    const searchInputBox = document?.querySelector('#search');
    const addEventListener = jest.spyOn(searchInputBox, 'addEventListener');
    initHeaderSearch();

    expect(addEventListener).toBeCalled();
  });

  it('removes event listener ', async () => {
    const removeEventListener = jest.fn();
    jest.mock('~/header_search', () => ({ initHeaderSearchApp: jest.fn() }));
    await eventHandler.apply(
      {
        newHeaderSearchFeatureFlag: true,
        searchInputBox: document.querySelector('#search'),
      },
      [removeEventListener],
    );

    expect(removeEventListener).toBeCalled();
  });

  it('attaches new vue dropdown  when feature flag is enabled', async () => {
    const mockVueApp = jest.fn();
    jest.mock('~/header_search', () => ({ initHeaderSearchApp: mockVueApp }));
    await eventHandler.apply(
      {
        newHeaderSearchFeatureFlag: true,
        searchInputBox: document.querySelector('#search'),
      },
      () => {},
    );

    expect(mockVueApp).toBeCalled();
  });

  it('attaches old vue dropdown when feature flag is disabled', async () => {
    const mockLegacyApp = jest.fn(() => ({
      onSearchInputFocus: jest.fn(),
    }));
    jest.mock('~/search_autocomplete', () => mockLegacyApp);
    await eventHandler.apply(
      {
        newHeaderSearchFeatureFlag: false,
        searchInputBox: document.querySelector('#search'),
      },
      () => {},
    );

    expect(mockLegacyApp).toBeCalled();
  });
});
