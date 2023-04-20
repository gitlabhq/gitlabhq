import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import initHeaderSearch, { eventHandler, cleanEventListeners } from '~/header_search/init';

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
    const addEventListenerSpy = jest.spyOn(searchInputBox, 'addEventListener');
    initHeaderSearch();

    expect(addEventListenerSpy).toHaveBeenCalledTimes(2);
  });

  it('removes event listener', async () => {
    const searchInputBox = document?.querySelector('#search');
    const removeEventListenerSpy = jest.spyOn(searchInputBox, 'removeEventListener');
    jest.mock('~/header_search', () => ({ initHeaderSearchApp: jest.fn() }));
    await eventHandler.apply(
      {
        searchInputBox: document.querySelector('#search'),
      },
      [cleanEventListeners],
    );

    expect(removeEventListenerSpy).toHaveBeenCalledTimes(2);
  });

  it('attaches new vue dropdown  when feature flag is enabled', async () => {
    const mockVueApp = jest.fn();
    jest.mock('~/header_search', () => ({ initHeaderSearchApp: mockVueApp }));
    await eventHandler.apply(
      {
        searchInputBox: document.querySelector('#search'),
      },
      () => {},
    );

    expect(mockVueApp).toHaveBeenCalled();
  });
});
