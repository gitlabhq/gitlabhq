import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { trimText } from 'helpers/text_helper';
import HeaderSearchScopedItems from '~/header_search/components/header_search_scoped_items.vue';
import { MOCK_SEARCH, MOCK_SCOPED_SEARCH_OPTIONS } from '../mock_data';

Vue.use(Vuex);

describe('HeaderSearchScopedItems', () => {
  let wrapper;

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        search: MOCK_SEARCH,
        ...initialState,
      },
      getters: {
        scopedSearchOptions: () => MOCK_SCOPED_SEARCH_OPTIONS,
      },
    });

    wrapper = shallowMount(HeaderSearchScopedItems, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemTitles = () => findDropdownItems().wrappers.map((w) => trimText(w.text()));
  const findDropdownItemLinks = () => findDropdownItems().wrappers.map((w) => w.attributes('href'));

  describe('template', () => {
    describe('Dropdown items', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders item for each option in scopedSearchOptions', () => {
        expect(findDropdownItems()).toHaveLength(MOCK_SCOPED_SEARCH_OPTIONS.length);
      });

      it('renders titles correctly', () => {
        const expectedTitles = MOCK_SCOPED_SEARCH_OPTIONS.map((o) =>
          trimText(`"${MOCK_SEARCH}" ${o.description} ${o.scope || ''}`),
        );
        expect(findDropdownItemTitles()).toStrictEqual(expectedTitles);
      });

      it('renders links correctly', () => {
        const expectedLinks = MOCK_SCOPED_SEARCH_OPTIONS.map((o) => o.url);
        expect(findDropdownItemLinks()).toStrictEqual(expectedLinks);
      });
    });
  });
});
