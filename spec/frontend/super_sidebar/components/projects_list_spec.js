import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import ProjectsList from '~/super_sidebar/components/projects_list.vue';
import SearchResults from '~/super_sidebar/components/search_results.vue';
import FrequentItemsList from '~/super_sidebar/components/frequent_items_list.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { MAX_FREQUENT_PROJECTS_COUNT } from '~/super_sidebar/constants';

const username = 'root';
const viewAllLink = '/path/to/projects';
const storageKey = `${username}/frequent-projects`;

describe('ProjectsList component', () => {
  let wrapper;

  const findSearchResults = () => wrapper.findComponent(SearchResults);
  const findFrequentItemsList = () => wrapper.findComponent(FrequentItemsList);
  const findViewAllLink = () => wrapper.findComponent(NavItem);

  const itRendersViewAllItem = () => {
    it('renders the "View all..." item', () => {
      const link = findViewAllLink();

      expect(link.props('item')).toEqual({
        icon: 'project',
        link: viewAllLink,
        title: s__('Navigation|View all your projects'),
      });
      expect(link.props('linkClasses')).toEqual({ 'dashboard-shortcuts-projects': true });
    });
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(ProjectsList, {
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
        title: s__('Navigation|Projects'),
        noResultsText: s__('Navigation|No project matches found'),
        searchResults,
      });
    });

    itRendersViewAllItem();
  });

  describe('when displaying frequent projects', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes the correct props to the frequent items list', () => {
      expect(findFrequentItemsList().props()).toEqual({
        title: s__('Navigation|Frequently visited projects'),
        storageKey,
        maxItems: MAX_FREQUENT_PROJECTS_COUNT,
        pristineText: s__('Navigation|Projects you visit often will appear here.'),
      });
    });

    itRendersViewAllItem();
  });
});
