import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RecentSearchesDropdownContent from '~/filtered_search/components/recent_searches_dropdown_content.vue';
import eventHub from '~/filtered_search/event_hub';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { TOKEN_TYPE_AUTHOR } from '~/vue_shared/components/filtered_search_bar/constants';

describe('Recent Searches Dropdown Content', () => {
  let wrapper;

  const findLocalStorageNote = () => wrapper.findByTestId('local-storage-note');
  const findDropdownItems = () => wrapper.findAllByTestId('dropdown-item');
  const findDropdownNote = () => wrapper.findByTestId('dropdown-note');

  const createComponent = (props) => {
    wrapper = shallowMountExtended(RecentSearchesDropdownContent, {
      propsData: {
        allowedKeys: IssuableFilteredSearchTokenKeys.getKeys(),
        items: [],
        isLocalStorageAvailable: false,
        ...props,
      },
    });
  };

  describe('when local storage is not available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a note about enabling local storage', () => {
      expect(findLocalStorageNote().exists()).toBe(true);
    });

    it('does not render dropdown items', () => {
      expect(findDropdownItems().exists()).toBe(false);
    });

    it('does not render dropdownNote', () => {
      expect(findDropdownNote().exists()).toBe(false);
    });
  });

  describe('when localStorage is available and items array is not empty', () => {
    let onRecentSearchesItemSelectedSpy;
    let onRequestClearRecentSearchesSpy;

    beforeAll(() => {
      onRecentSearchesItemSelectedSpy = jest.fn();
      onRequestClearRecentSearchesSpy = jest.fn();
      eventHub.$on('recentSearchesItemSelected', onRecentSearchesItemSelectedSpy);
      eventHub.$on('requestClearRecentSearches', onRequestClearRecentSearchesSpy);
    });

    beforeEach(() => {
      createComponent({
        items: [
          'foo',
          'author:@root label:~foo bar',
          [{ type: TOKEN_TYPE_AUTHOR, value: { data: 'toby', operator: '=' } }],
        ],
        isLocalStorageAvailable: true,
      });
    });

    afterAll(() => {
      eventHub.$off('recentSearchesItemSelected', onRecentSearchesItemSelectedSpy);
      eventHub.$off('requestClearRecentSearchesSpy', onRequestClearRecentSearchesSpy);
    });

    it('does not render a note about enabling local storage', () => {
      expect(findLocalStorageNote().exists()).toBe(false);
    });

    it('does not render dropdownNote', () => {
      expect(findDropdownNote().exists()).toBe(false);
    });

    it('renders a correct amount of dropdown items', () => {
      expect(findDropdownItems()).toHaveLength(2); // Ignore non-string recent item
    });

    it('expect second dropdown to have 2 tokens', () => {
      expect(findDropdownItems().at(1).findAll('.js-dropdown-token')).toHaveLength(2);
    });

    it('emits recentSearchesItemSelected on dropdown item click', () => {
      findDropdownItems().at(0).find('.js-dropdown-button').trigger('click');

      expect(onRecentSearchesItemSelectedSpy).toHaveBeenCalledWith('foo');
    });

    it('emits requestClearRecentSearches on Clear resent searches button', () => {
      wrapper.findByTestId('clear-button').trigger('click');

      expect(onRequestClearRecentSearchesSpy).toHaveBeenCalled();
    });
  });

  describe('when locale storage is available and items array is empty', () => {
    beforeEach(() => {
      createComponent({
        isLocalStorageAvailable: true,
      });
    });

    it('does not render a note about enabling local storage', () => {
      expect(findLocalStorageNote().exists()).toBe(false);
    });

    it('does not render dropdown items', () => {
      expect(findDropdownItems().exists()).toBe(false);
    });

    it('renders dropdown note', () => {
      expect(findDropdownNote().exists()).toBe(true);
    });
  });
});
