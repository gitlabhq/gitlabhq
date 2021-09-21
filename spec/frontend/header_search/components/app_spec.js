import { GlSearchBoxByType } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderSearchApp from '~/header_search/components/app.vue';
import HeaderSearchAutocompleteItems from '~/header_search/components/header_search_autocomplete_items.vue';
import HeaderSearchDefaultItems from '~/header_search/components/header_search_default_items.vue';
import HeaderSearchScopedItems from '~/header_search/components/header_search_scoped_items.vue';
import { ENTER_KEY, ESC_KEY } from '~/lib/utils/keys';
import { visitUrl } from '~/lib/utils/url_utility';
import { MOCK_SEARCH, MOCK_SEARCH_QUERY, MOCK_USERNAME } from '../mock_data';

Vue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

describe('HeaderSearchApp', () => {
  let wrapper;

  const actionSpies = {
    setSearch: jest.fn(),
    fetchAutocompleteOptions: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        searchQuery: () => MOCK_SEARCH_QUERY,
      },
    });

    wrapper = shallowMountExtended(HeaderSearchApp, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeaderSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findHeaderSearchDropdown = () => wrapper.findByTestId('header-search-dropdown-menu');
  const findHeaderSearchDefaultItems = () => wrapper.findComponent(HeaderSearchDefaultItems);
  const findHeaderSearchScopedItems = () => wrapper.findComponent(HeaderSearchScopedItems);
  const findHeaderSearchAutocompleteItems = () =>
    wrapper.findComponent(HeaderSearchAutocompleteItems);

  describe('template', () => {
    it('always renders Header Search Input', () => {
      createComponent();
      expect(findHeaderSearchInput().exists()).toBe(true);
    });

    describe.each`
      showDropdown | username         | showSearchDropdown
      ${false}     | ${null}          | ${false}
      ${false}     | ${MOCK_USERNAME} | ${false}
      ${true}      | ${null}          | ${false}
      ${true}      | ${MOCK_USERNAME} | ${true}
    `('Header Search Dropdown', ({ showDropdown, username, showSearchDropdown }) => {
      describe(`when showDropdown is ${showDropdown} and current_username is ${username}`, () => {
        beforeEach(() => {
          createComponent();
          window.gon.current_username = username;
          wrapper.setData({ showDropdown });
        });

        it(`should${showSearchDropdown ? '' : ' not'} render`, () => {
          expect(findHeaderSearchDropdown().exists()).toBe(showSearchDropdown);
        });
      });
    });

    describe.each`
      search         | showDefault | showScoped | showAutocomplete
      ${null}        | ${true}     | ${false}   | ${false}
      ${''}          | ${true}     | ${false}   | ${false}
      ${MOCK_SEARCH} | ${false}    | ${true}    | ${true}
    `('Header Search Dropdown Items', ({ search, showDefault, showScoped, showAutocomplete }) => {
      describe(`when search is ${search}`, () => {
        beforeEach(() => {
          createComponent({ search });
          window.gon.current_username = MOCK_USERNAME;
          wrapper.setData({ showDropdown: true });
        });

        it(`should${showDefault ? '' : ' not'} render the Default Dropdown Items`, () => {
          expect(findHeaderSearchDefaultItems().exists()).toBe(showDefault);
        });

        it(`should${showScoped ? '' : ' not'} render the Scoped Dropdown Items`, () => {
          expect(findHeaderSearchScopedItems().exists()).toBe(showScoped);
        });

        it(`should${showAutocomplete ? '' : ' not'} render the Autocomplete Dropdown Items`, () => {
          expect(findHeaderSearchAutocompleteItems().exists()).toBe(showAutocomplete);
        });
      });
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
      window.gon.current_username = MOCK_USERNAME;
    });

    describe('Header Search Input', () => {
      describe('when dropdown is closed', () => {
        it('onFocus opens dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          findHeaderSearchInput().vm.$emit('focus');

          await wrapper.vm.$nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(true);
        });

        it('onClick opens dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(false);
          findHeaderSearchInput().vm.$emit('click');

          await wrapper.vm.$nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(true);
        });
      });

      describe('when dropdown is opened', () => {
        beforeEach(() => {
          wrapper.setData({ showDropdown: true });
        });

        it('onKey-Escape closes dropdown', async () => {
          expect(findHeaderSearchDropdown().exists()).toBe(true);
          findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ESC_KEY }));

          await wrapper.vm.$nextTick();

          expect(findHeaderSearchDropdown().exists()).toBe(false);
        });
      });

      describe('onInput', () => {
        beforeEach(() => {
          findHeaderSearchInput().vm.$emit('input', MOCK_SEARCH);
        });

        it('calls setSearch with search term', () => {
          expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), MOCK_SEARCH);
        });

        it('calls fetchAutocompleteOptions', () => {
          expect(actionSpies.fetchAutocompleteOptions).toHaveBeenCalled();
        });
      });

      it('submits a search onKey-Enter', async () => {
        findHeaderSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        await wrapper.vm.$nextTick();

        expect(visitUrl).toHaveBeenCalledWith(MOCK_SEARCH_QUERY);
      });
    });
  });
});
