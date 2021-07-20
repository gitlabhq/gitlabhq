import FilteredSearchManager from 'ee_else_ce/filtered_search/filtered_search_manager';

import FilteredSearchSpecHelper from 'helpers/filtered_search_spec_helper';
import DropdownUtils from '~/filtered_search/dropdown_utils';
import FilteredSearchDropdownManager from '~/filtered_search/filtered_search_dropdown_manager';
import FilteredSearchVisualTokens from '~/filtered_search/filtered_search_visual_tokens';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import RecentSearchesRoot from '~/filtered_search/recent_searches_root';
import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import RecentSearchesServiceError from '~/filtered_search/services/recent_searches_service_error';
import createFlash from '~/flash';
import { BACKSPACE_KEY_CODE, DELETE_KEY_CODE } from '~/lib/utils/keycodes';
import { visitUrl, getParameterByName } from '~/lib/utils/url_utility';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterByName: jest.fn(),
  visitUrl: jest.fn(),
}));

describe('Filtered Search Manager', () => {
  let input;
  let manager;
  let tokensContainer;
  const page = 'issues';
  const placeholder = 'Search or filter results...';

  function dispatchBackspaceEvent(element, eventType) {
    const event = new Event(eventType);
    event.keyCode = BACKSPACE_KEY_CODE;
    element.dispatchEvent(event);
  }

  function dispatchDeleteEvent(element, eventType) {
    const event = new Event(eventType);
    event.keyCode = DELETE_KEY_CODE;
    element.dispatchEvent(event);
  }

  function dispatchAltBackspaceEvent(element, eventType) {
    const event = new Event(eventType);
    event.altKey = true;
    event.keyCode = BACKSPACE_KEY_CODE;
    element.dispatchEvent(event);
  }

  function dispatchCtrlBackspaceEvent(element, eventType) {
    const event = new Event(eventType);
    event.ctrlKey = true;
    event.keyCode = BACKSPACE_KEY_CODE;
    element.dispatchEvent(event);
  }

  function dispatchMetaBackspaceEvent(element, eventType) {
    const event = new Event(eventType);
    event.metaKey = true;
    event.keyCode = BACKSPACE_KEY_CODE;
    element.dispatchEvent(event);
  }

  function getVisualTokens() {
    return tokensContainer.querySelectorAll('.js-visual-token');
  }

  beforeEach(() => {
    setFixtures(`
      <div class="filtered-search-box">
        <form>
          <ul class="tokens-container list-unstyled">
            ${FilteredSearchSpecHelper.createInputHTML(placeholder)}
          </ul>
          <button class="clear-search" type="button">
            <svg class="s16 clear-search-icon" data-testid="close-icon"><use xlink:href="icons.svg#close" /></svg>
          </button>
        </form>
      </div>
    `);

    jest.spyOn(FilteredSearchDropdownManager.prototype, 'setDropdown').mockImplementation();
  });

  const initializeManager = ({ useDefaultState } = {}) => {
    jest.spyOn(FilteredSearchManager.prototype, 'loadSearchParamsFromURL').mockImplementation();
    jest.spyOn(FilteredSearchManager.prototype, 'tokenChange').mockImplementation();
    jest
      .spyOn(FilteredSearchDropdownManager.prototype, 'updateDropdownOffset')
      .mockImplementation();
    jest.spyOn(FilteredSearchVisualTokens, 'unselectTokens');

    getParameterByName.mockReturnValue(null);

    input = document.querySelector('.filtered-search');
    tokensContainer = document.querySelector('.tokens-container');
    manager = new FilteredSearchManager({ page, useDefaultState });
    manager.setup();
  };

  afterEach(() => {
    manager.cleanup();
  });

  describe('class constructor', () => {
    const isLocalStorageAvailable = 'isLocalStorageAvailable';

    beforeEach(() => {
      jest.spyOn(RecentSearchesService, 'isAvailable').mockReturnValue(isLocalStorageAvailable);
      jest.spyOn(RecentSearchesRoot.prototype, 'render').mockImplementation();
    });

    it('should instantiate RecentSearchesStore with isLocalStorageAvailable', () => {
      manager = new FilteredSearchManager({ page });

      expect(RecentSearchesService.isAvailable).toHaveBeenCalled();
      expect(manager.recentSearchesStore.state).toEqual(
        expect.objectContaining({
          isLocalStorageAvailable,
          allowedKeys: IssuableFilteredSearchTokenKeys.getKeys(),
        }),
      );
    });
  });

  describe('setup', () => {
    beforeEach(() => {
      manager = new FilteredSearchManager({ page });
    });

    it('should not instantiate Flash if an RecentSearchesServiceError is caught', () => {
      jest
        .spyOn(RecentSearchesService.prototype, 'fetch')
        .mockImplementation(() => Promise.reject(new RecentSearchesServiceError()));

      manager.setup();

      expect(createFlash).not.toHaveBeenCalled();
    });
  });

  describe('searchState', () => {
    beforeEach(() => {
      jest.spyOn(FilteredSearchManager.prototype, 'search').mockImplementation();
      initializeManager();
    });

    it('should blur button', () => {
      const e = {
        preventDefault: () => {},
        currentTarget: {
          blur: () => {},
        },
      };
      jest.spyOn(e.currentTarget, 'blur');
      manager.searchState(e);

      expect(e.currentTarget.blur).toHaveBeenCalled();
    });

    it('should not call search if there is no state', () => {
      const e = {
        preventDefault: () => {},
        currentTarget: {
          blur: () => {},
        },
      };

      manager.searchState(e);

      expect(FilteredSearchManager.prototype.search).not.toHaveBeenCalled();
    });

    it('should call search when there is state', () => {
      const e = {
        preventDefault: () => {},
        currentTarget: {
          blur: () => {},
          dataset: {
            state: 'opened',
          },
        },
      };

      manager.searchState(e);

      expect(FilteredSearchManager.prototype.search).toHaveBeenCalledWith('opened');
    });
  });

  describe('search', () => {
    const defaultParams = '?scope=all';
    const defaultState = '&state=opened';

    it('should search with a single word', (done) => {
      initializeManager();
      input.value = 'searchTerm';

      visitUrl.mockImplementation((url) => {
        expect(url).toEqual(`${defaultParams}&search=searchTerm`);
        done();
      });

      manager.search();
    });

    it('sets default state', (done) => {
      initializeManager({ useDefaultState: true });
      input.value = 'searchTerm';

      visitUrl.mockImplementation((url) => {
        expect(url).toEqual(`${defaultParams}${defaultState}&search=searchTerm`);
        done();
      });

      manager.search();
    });

    it('should search with multiple words', (done) => {
      initializeManager();
      input.value = 'awesome search terms';

      visitUrl.mockImplementation((url) => {
        expect(url).toEqual(`${defaultParams}&search=awesome+search+terms`);
        done();
      });

      manager.search();
    });

    it('should search with special characters', (done) => {
      initializeManager();
      input.value = '~!@#$%^&*()_+{}:<>,.?/';

      visitUrl.mockImplementation((url) => {
        expect(url).toEqual(
          `${defaultParams}&search=~!%40%23%24%25%5E%26*()_%2B%7B%7D%3A%3C%3E%2C.%3F%2F`,
        );
        done();
      });

      manager.search();
    });

    it('should use replacement URL for condition', (done) => {
      initializeManager();
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', '=', '13', true),
      );

      visitUrl.mockImplementation((url) => {
        expect(url).toEqual(`${defaultParams}&milestone_title=replaced`);
        done();
      });

      manager.filteredSearchTokenKeys.conditions.push({
        url: 'milestone_title=13',
        replacementUrl: 'milestone_title=replaced',
        tokenKey: 'milestone',
        value: '13',
        operator: '=',
      });
      manager.search();
    });

    it('removes duplicated tokens', (done) => {
      initializeManager();
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '=', '~bug')}
        ${FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '=', '~bug')}
      `);

      visitUrl.mockImplementation((url) => {
        expect(url).toEqual(`${defaultParams}&label_name[]=bug`);
        done();
      });

      manager.search();
    });
  });

  describe('handleInputPlaceholder', () => {
    beforeEach(() => {
      initializeManager();
    });

    it('should render placeholder when there is no input', () => {
      expect(input.placeholder).toEqual(placeholder);
    });

    it('should not render placeholder when there is input', () => {
      input.value = 'test words';

      const event = new Event('input');
      input.dispatchEvent(event);

      expect(input.placeholder).toEqual('');
    });

    it('should not render placeholder when there are tokens and no input', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '=', '~bug'),
      );

      const event = new Event('input');
      input.dispatchEvent(event);

      expect(input.placeholder).toEqual('');
    });
  });

  describe('checkForBackspace', () => {
    beforeEach(() => {
      initializeManager();
    });

    describe('tokens and no input', () => {
      beforeEach(() => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '=', '~bug'),
        );
      });

      it('removes last token', () => {
        jest.spyOn(FilteredSearchVisualTokens, 'removeLastTokenPartial');
        dispatchBackspaceEvent(input, 'keyup');
        dispatchBackspaceEvent(input, 'keyup');

        expect(FilteredSearchVisualTokens.removeLastTokenPartial).toHaveBeenCalled();
      });

      it('sets the input', () => {
        jest.spyOn(FilteredSearchVisualTokens, 'getLastTokenPartial');
        dispatchDeleteEvent(input, 'keyup');
        dispatchDeleteEvent(input, 'keyup');

        expect(FilteredSearchVisualTokens.getLastTokenPartial).toHaveBeenCalled();
        expect(input.value).toEqual('~bug');
      });
    });

    it('does not remove token or change input when there is existing input', () => {
      jest.spyOn(FilteredSearchVisualTokens, 'removeLastTokenPartial');
      jest.spyOn(FilteredSearchVisualTokens, 'getLastTokenPartial');

      input.value = 'text';
      dispatchDeleteEvent(input, 'keyup');

      expect(FilteredSearchVisualTokens.removeLastTokenPartial).not.toHaveBeenCalled();
      expect(FilteredSearchVisualTokens.getLastTokenPartial).not.toHaveBeenCalled();
      expect(input.value).toEqual('text');
    });

    it('does not remove previous token on single backspace press', () => {
      jest.spyOn(FilteredSearchVisualTokens, 'removeLastTokenPartial');
      jest.spyOn(FilteredSearchVisualTokens, 'getLastTokenPartial');

      input.value = 't';
      dispatchDeleteEvent(input, 'keyup');

      expect(FilteredSearchVisualTokens.removeLastTokenPartial).not.toHaveBeenCalled();
      expect(FilteredSearchVisualTokens.getLastTokenPartial).not.toHaveBeenCalled();
      expect(input.value).toEqual('t');
    });
  });

  describe('checkForAltOrCtrlBackspace', () => {
    beforeEach(() => {
      initializeManager();
      jest.spyOn(FilteredSearchVisualTokens, 'removeLastTokenPartial');
    });

    describe('tokens and no input', () => {
      beforeEach(() => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '=', '~bug'),
        );
      });

      it('removes last token via alt-backspace', () => {
        dispatchAltBackspaceEvent(input, 'keydown');

        expect(FilteredSearchVisualTokens.removeLastTokenPartial).toHaveBeenCalled();
      });

      it('removes last token via ctrl-backspace', () => {
        dispatchCtrlBackspaceEvent(input, 'keydown');

        expect(FilteredSearchVisualTokens.removeLastTokenPartial).toHaveBeenCalled();
      });
    });

    describe('tokens and input', () => {
      beforeEach(() => {
        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '=', '~bug'),
        );
      });

      it('does not remove token or change input via alt-backspace when there is existing input', () => {
        input = manager.filteredSearchInput;
        input.value = 'text';
        dispatchAltBackspaceEvent(input, 'keydown');

        expect(FilteredSearchVisualTokens.removeLastTokenPartial).not.toHaveBeenCalled();
        expect(input.value).toEqual('text');
      });

      it('does not remove token or change input via ctrl-backspace when there is existing input', () => {
        input = manager.filteredSearchInput;
        input.value = 'text';
        dispatchCtrlBackspaceEvent(input, 'keydown');

        expect(FilteredSearchVisualTokens.removeLastTokenPartial).not.toHaveBeenCalled();
        expect(input.value).toEqual('text');
      });
    });
  });

  describe('checkForMetaBackspace', () => {
    beforeEach(() => {
      initializeManager();
    });

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('label', '=', '~bug'),
      );
    });

    it('removes all tokens and input', () => {
      jest.spyOn(FilteredSearchManager.prototype, 'clearSearch');
      dispatchMetaBackspaceEvent(input, 'keydown');

      expect(manager.clearSearch).toHaveBeenCalled();
      expect(manager.filteredSearchInput.value).toEqual('');
      expect(DropdownUtils.getSearchQuery()).toEqual('');
    });
  });

  describe('removeToken', () => {
    beforeEach(() => {
      initializeManager();
    });

    it('removes token even when it is already selected', () => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', '=', 'none', true),
      );

      tokensContainer.querySelector('.js-visual-token .remove-token').click();

      expect(tokensContainer.querySelector('.js-visual-token')).toEqual(null);
    });

    describe('unselected token', () => {
      beforeEach(() => {
        jest.spyOn(FilteredSearchManager.prototype, 'removeSelectedToken');

        tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
          FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', '=', 'none'),
        );
        tokensContainer.querySelector('.js-visual-token .remove-token').click();
      });

      it('removes token when remove button is selected', () => {
        expect(tokensContainer.querySelector('.js-visual-token')).toEqual(null);
      });

      it('calls removeSelectedToken', () => {
        expect(manager.removeSelectedToken).toHaveBeenCalled();
      });
    });
  });

  describe('removeSelectedTokenKeydown', () => {
    beforeEach(() => {
      initializeManager();
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(
        FilteredSearchSpecHelper.createFilterVisualTokenHTML('milestone', '=', 'none', true),
      );
    });

    it('removes selected token when the backspace key is pressed', () => {
      expect(getVisualTokens().length).toEqual(1);

      dispatchBackspaceEvent(document, 'keydown');

      expect(getVisualTokens().length).toEqual(0);
    });

    it('removes selected token when the delete key is pressed', () => {
      expect(getVisualTokens().length).toEqual(1);

      dispatchDeleteEvent(document, 'keydown');

      expect(getVisualTokens().length).toEqual(0);
    });

    it('updates the input placeholder after removal', () => {
      manager.handleInputPlaceholder();

      expect(input.placeholder).toEqual('');
      expect(getVisualTokens().length).toEqual(1);

      dispatchBackspaceEvent(document, 'keydown');

      expect(input.placeholder).not.toEqual('');
      expect(getVisualTokens().length).toEqual(0);
    });

    it('updates the clear button after removal', () => {
      manager.toggleClearSearchButton();

      const clearButton = document.querySelector('.clear-search');

      expect(clearButton.classList.contains('hidden')).toEqual(false);
      expect(getVisualTokens().length).toEqual(1);

      dispatchBackspaceEvent(document, 'keydown');

      expect(clearButton.classList.contains('hidden')).toEqual(true);
      expect(getVisualTokens().length).toEqual(0);
    });
  });

  describe('removeSelectedToken', () => {
    beforeEach(() => {
      jest.spyOn(FilteredSearchVisualTokens, 'removeSelectedToken');
      jest.spyOn(FilteredSearchManager.prototype, 'handleInputPlaceholder');
      jest.spyOn(FilteredSearchManager.prototype, 'toggleClearSearchButton');
      initializeManager();
    });

    it('calls FilteredSearchVisualTokens.removeSelectedToken', () => {
      manager.removeSelectedToken();

      expect(FilteredSearchVisualTokens.removeSelectedToken).toHaveBeenCalled();
    });

    it('calls handleInputPlaceholder', () => {
      manager.removeSelectedToken();

      expect(manager.handleInputPlaceholder).toHaveBeenCalled();
    });

    it('calls toggleClearSearchButton', () => {
      manager.removeSelectedToken();

      expect(manager.toggleClearSearchButton).toHaveBeenCalled();
    });

    it('calls update dropdown offset', () => {
      manager.removeSelectedToken();

      expect(manager.dropdownManager.updateDropdownOffset).toHaveBeenCalled();
    });
  });

  describe('Clearing search', () => {
    beforeEach(() => {
      initializeManager();
    });

    it('Clicking the "x" clear button, clears the input', () => {
      const inputValue = 'label:=~bug';
      manager.filteredSearchInput.value = inputValue;
      manager.filteredSearchInput.dispatchEvent(new Event('input'));

      expect(DropdownUtils.getSearchQuery()).toEqual(inputValue);

      manager.clearSearchButton.click();

      expect(manager.filteredSearchInput.value).toEqual('');
      expect(DropdownUtils.getSearchQuery()).toEqual('');
    });
  });

  describe('toggleInputContainerFocus', () => {
    beforeEach(() => {
      initializeManager();
    });

    it('toggles on focus', () => {
      input.focus();

      expect(document.querySelector('.filtered-search-box').classList.contains('focus')).toEqual(
        true,
      );
    });

    it('toggles on blur', () => {
      input.blur();

      expect(document.querySelector('.filtered-search-box').classList.contains('focus')).toEqual(
        false,
      );
    });
  });

  describe('getAllParams', () => {
    let paramsArr;
    beforeEach(() => {
      paramsArr = ['key=value', 'otherkey=othervalue'];

      initializeManager();
    });

    it('correctly modifies params when custom modifier is passed', () => {
      const modifedParams = manager.getAllParams.call(
        {
          modifyUrlParams: (params) => params.reverse(),
        },
        [].concat(paramsArr),
      );

      expect(modifedParams[0]).toBe(paramsArr[1]);
    });

    it('does not modify params when no custom modifier is passed', () => {
      const modifedParams = manager.getAllParams.call({}, paramsArr);

      expect(modifedParams[1]).toBe(paramsArr[1]);
    });
  });
});
