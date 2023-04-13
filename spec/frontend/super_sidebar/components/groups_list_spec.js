import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import GroupsList from '~/super_sidebar/components/groups_list.vue';
import SearchResults from '~/super_sidebar/components/search_results.vue';
import FrequentItemsList from '~/super_sidebar/components/frequent_items_list.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { MAX_FREQUENT_GROUPS_COUNT } from '~/super_sidebar/constants';

const username = 'root';
const viewAllLink = '/path/to/groups';
const storageKey = `${username}/frequent-groups`;

describe('GroupsList component', () => {
  let wrapper;

  const findSearchResults = () => wrapper.findComponent(SearchResults);
  const findFrequentItemsList = () => wrapper.findComponent(FrequentItemsList);
  const findViewAllLink = () => wrapper.findComponent(NavItem);

  const itRendersViewAllItem = () => {
    it('renders the "View all..." item', () => {
      const link = findViewAllLink();

      expect(link.props('item')).toEqual({
        icon: 'group',
        link: viewAllLink,
        title: s__('Navigation|View all your groups'),
      });
      expect(link.props('linkClasses')).toEqual({ 'dashboard-shortcuts-groups': true });
    });
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(GroupsList, {
      propsData: {
        username,
        viewAllLink,
        ...props,
      },
    });
  };

  describe('when displaying search results', () => {
    const searchResults = ['A search result'];

    beforeEach(() => {
      createWrapper({
        isSearch: true,
        searchResults,
      });
    });

    it('renders the search results component', () => {
      expect(findSearchResults().exists()).toBe(true);
      expect(findFrequentItemsList().exists()).toBe(false);
    });

    it('passes the correct props to the search results component', () => {
      expect(findSearchResults().props()).toEqual({
        title: s__('Navigation|Groups'),
        noResultsText: s__('Navigation|No group matches found'),
        searchResults,
      });
    });

    itRendersViewAllItem();
  });

  describe('when displaying frequent groups', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the frequent items list', () => {
      expect(findFrequentItemsList().exists()).toBe(true);
      expect(findSearchResults().exists()).toBe(false);
    });

    it('passes the correct props to the frequent items list', () => {
      expect(findFrequentItemsList().props()).toEqual({
        title: s__('Navigation|Frequently visited groups'),
        storageKey,
        maxItems: MAX_FREQUENT_GROUPS_COUNT,
        pristineText: s__('Navigation|Groups you visit often will appear here.'),
      });
    });

    itRendersViewAllItem();
  });
});
