import { GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import SearchResults from '~/super_sidebar/components/search_results.vue';
import ItemsList from '~/super_sidebar/components/items_list.vue';
import { stubComponent } from 'helpers/stub_component';

const title = s__('Navigation|PROJECTS');
const noResultsText = s__('Navigation|No project matches found');

describe('SearchResults component', () => {
  let wrapper;

  const findSearchResultsToggle = () => wrapper.findByTestId('search-results-toggle');
  const findCollapsibleSection = () => wrapper.findComponent(GlCollapse);
  const findItemsList = () => wrapper.findComponent(ItemsList);
  const findEmptyText = () => wrapper.findByTestId('empty-text');

  const createWrapper = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(SearchResults, {
      propsData: {
        title,
        noResultsText,
        ...props,
      },
      stubs: {
        GlCollapse: stubComponent(GlCollapse, {
          props: ['visible'],
        }),
      },
    });
  };

  describe('default state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it("renders the list's title", () => {
      expect(findSearchResultsToggle().text()).toBe(title);
    });

    it('is expanded', () => {
      expect(findCollapsibleSection().props('visible')).toBe(true);
    });

    it('renders the empty text', () => {
      expect(findEmptyText().exists()).toBe(true);
      expect(findEmptyText().text()).toBe(noResultsText);
    });
  });

  describe('when displaying search results', () => {
    it('shows search results', () => {
      const searchResults = [{ id: 1 }];
      createWrapper({ props: { isSearch: true, searchResults } });

      expect(findItemsList().props('items')[0]).toEqual(searchResults[0]);
    });

    it('shows the no results text if search results are empty', () => {
      const searchResults = [];
      createWrapper({ props: { isSearch: true, searchResults } });

      expect(findItemsList().props('items').length).toEqual(0);
      expect(findEmptyText().text()).toBe(noResultsText);
    });
  });
});
