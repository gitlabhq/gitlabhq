import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlToken, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { trimText } from 'helpers/text_helper';
import GlobalSearchScopedItems from '~/super_sidebar/components/global_search/components/global_search_scoped_items.vue';
import { truncate } from '~/lib/utils/text_utility';
import { SCOPE_TOKEN_MAX_LENGTH } from '~/super_sidebar/components/global_search/constants';
import { MSG_IN_ALL_GITLAB } from '~/vue_shared/global_search/constants';
import {
  MOCK_SEARCH,
  MOCK_SCOPED_SEARCH_GROUP,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
} from '../mock_data';

Vue.use(Vuex);

describe('GlobalSearchScopedItems', () => {
  let wrapper;

  const createComponent = (initialState, mockGetters, props) => {
    const store = new Vuex.Store({
      state: {
        search: MOCK_SEARCH,
        ...initialState,
      },
      getters: {
        scopedSearchGroup: () => MOCK_SCOPED_SEARCH_GROUP,
        autocompleteGroupedSearchOptions: () => MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = shallowMount(GlobalSearchScopedItems, {
      store,
      propsData: {
        ...props,
      },
      stubs: {
        GlDisclosureDropdownGroup,
        GlDisclosureDropdownItem,
      },
    });
  };

  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findItemsText = () => findItems().wrappers.map((w) => trimText(w.text()));
  const findScopeTokens = () => wrapper.findAllComponents(GlToken);
  const findScopeTokensText = () => findScopeTokens().wrappers.map((w) => trimText(w.text()));
  const findScopeTokensIcons = () =>
    findScopeTokens().wrappers.map((w) => w.findAllComponents(GlIcon));
  const findItemLinks = () => findItems().wrappers.map((w) => w.find('a').attributes('href'));

  describe('Search results scoped items', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders item for each item in scopedSearchGroup', () => {
      expect(findItems()).toHaveLength(MOCK_SCOPED_SEARCH_GROUP.items.length);
    });

    it('renders titles correctly', () => {
      findItemsText().forEach((title) => expect(title).toContain(MOCK_SEARCH));
    });

    it('renders scope names correctly', () => {
      const expectedTitles = MOCK_SCOPED_SEARCH_GROUP.items.map((o) =>
        truncate(trimText(`in ${o.scope || o.description}`), SCOPE_TOKEN_MAX_LENGTH),
      );

      expect(findScopeTokensText()).toStrictEqual(expectedTitles);
    });

    it('renders scope icons correctly', () => {
      findScopeTokensIcons().forEach((icon, i) => {
        const w = icon.wrappers[0];
        expect(w?.attributes('name')).toBe(MOCK_SCOPED_SEARCH_GROUP.items[i].icon);
      });
    });

    it(`renders scope ${MSG_IN_ALL_GITLAB} correctly`, () => {
      expect(findScopeTokens().at(-1).findComponent(GlIcon).exists()).toBe(false);
    });

    it('renders links correctly', () => {
      const expectedLinks = MOCK_SCOPED_SEARCH_GROUP.items.map((o) => o.href);
      expect(findItemLinks()).toStrictEqual(expectedLinks);
    });
  });
});
