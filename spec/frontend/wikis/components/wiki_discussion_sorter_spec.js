import { GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiDiscussionSorter from '~/wikis/wiki_notes/components/wiki_discussion_sorter.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import initCache from '~/wikis/graphql/notes/cache_init';
import sortWikiDiscussion from '~/wikis/graphql/notes/sort_wiki_discussion.mutation.graphql';
import wikiDiscussionSortOrder from '~/wikis/graphql/notes/wiki_discussion_sort_order.query.graphql';

Vue.use(VueApollo);

describe('WikiDiscussionSorter', () => {
  let wrapper;
  let mockApollo;

  const updateCacheState = (value) => {
    mockApollo.defaultClient.cache.writeQuery({
      query: wikiDiscussionSortOrder,
      data: {
        wikiDiscussionSortOrder: value,
      },
    });
  };

  const setupMockApollo = (shouldInitCache = true) => {
    mockApollo = createMockApollo();
    if (shouldInitCache) {
      initCache(mockApollo.defaultClient.cache);
    }
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(WikiDiscussionSorter, {
      apolloProvider: mockApollo,
      stubs: {
        GlDisclosureDropdownItem,
      },
    });
  };

  const findSortOrderDropdown = () => wrapper.findByTestId('discussion-sort-dropdown');
  const findSortByNewestFirst = () =>
    findSortOrderDropdown().findAllComponents(GlDisclosureDropdownItem).at(0);
  const findSortByOldestFirst = () =>
    findSortOrderDropdown().findAllComponents(GlDisclosureDropdownItem).at(1);

  describe('rendering', () => {
    beforeEach(() => {
      setupMockApollo();
      createComponent();
    });

    it('renders the sort dropdown', () => {
      expect(findSortOrderDropdown().exists()).toBe(true);
    });

    it('displays all sort options', () => {
      expect(findSortByNewestFirst().text()).toBe('Newest first');
      expect(findSortByOldestFirst().text()).toBe('Oldest first');
    });

    it('shows the current sort value as selected', () => {
      expect(findSortByNewestFirst().attributes('is-selected')).not.toBe('true');
      expect(findSortByOldestFirst().attributes('is-selected')).toBe('true');
    });
  });

  describe('interactions', () => {
    it('emits sort-changed event when selection changes', () => {
      setupMockApollo();
      createComponent();

      jest.spyOn(mockApollo.defaultClient, 'mutate');
      findSortByNewestFirst().vm.$emit('action');

      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: sortWikiDiscussion,
        variables: {
          sortOrder: 'created_desc',
        },
      });
    });

    it('updates displayed selected value according to cache state', () => {
      setupMockApollo();
      updateCacheState('created_desc');
      createComponent();

      expect(findSortByNewestFirst().attributes('is-selected')).toBe('true');
      expect(findSortByOldestFirst().attributes('is-selected')).not.toBe('true');
    });
  });

  describe('edge cases', () => {
    it('renders without crashing when cache is not initialised', () => {
      setupMockApollo(false);
      createComponent();
      expect(wrapper.exists()).toBe(true);
    });
  });
});
