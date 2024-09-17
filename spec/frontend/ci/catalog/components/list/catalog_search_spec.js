import { GlSearchBoxByClick, GlSorting } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CatalogSearch from '~/ci/catalog/components/list/catalog_search.vue';
import {
  SORT_ASC,
  SORT_DESC,
  SORT_OPTION_CREATED,
  SORT_OPTION_POPULARITY,
  SORT_OPTION_STAR_COUNT,
} from '~/ci/catalog/constants';

describe('CatalogSearch', () => {
  let wrapper;

  const findSearchBar = () => wrapper.findComponent(GlSearchBoxByClick);
  const findSorting = () => wrapper.findComponent(GlSorting);
  const findAllSortingItems = () => findSorting().props('sortOptions');

  const createComponent = () => {
    wrapper = shallowMountExtended(CatalogSearch);
  };

  describe('default UI', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the search bar', () => {
      expect(findSearchBar().exists()).toBe(true);
    });

    it('adds sorting options', () => {
      const sortOptionsProp = findAllSortingItems();
      expect(sortOptionsProp).toHaveLength(4);
      expect(sortOptionsProp[0].text).toBe('Popularity');
    });

    it('renders the `Popularity` option as the default', () => {
      expect(findSorting().props('text')).toBe('Popularity');
    });
  });

  describe('search', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes down the search value to the search component', async () => {
      const newSearchTerm = 'cat';

      expect(findSearchBar().props().value).toBe('');

      await findSearchBar().vm.$emit('input', newSearchTerm);

      expect(findSearchBar().props().value).toBe(newSearchTerm);
    });

    it('does not submit only when typing', async () => {
      expect(wrapper.emitted('update-search-term')).toBeUndefined();

      await findSearchBar().vm.$emit('input', 'new');

      expect(wrapper.emitted('update-search-term')).toBeUndefined();
    });

    describe('when submitting the search', () => {
      const newSearchTerm = 'dog';

      beforeEach(async () => {
        await findSearchBar().vm.$emit('input', newSearchTerm);
        await findSearchBar().vm.$emit('submit');
      });

      it('emits the event up with the new payload', () => {
        expect(wrapper.emitted('update-search-term')).toEqual([[newSearchTerm]]);
      });
    });

    describe('when clearing the search', () => {
      beforeEach(async () => {
        await findSearchBar().vm.$emit('input', 'new');
        await findSearchBar().vm.$emit('clear');
      });

      it('emits an update event with an empty string payload', () => {
        expect(wrapper.emitted('update-search-term')).toEqual([['']]);
      });
    });
  });

  describe('sort', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when changing sort order', () => {
      it('changes the `isAscending` prop to the sorting component', async () => {
        expect(findSorting().props().isAscending).toBe(false);

        await findSorting().vm.$emit('sortDirectionChange');

        expect(findSorting().props().isAscending).toBe(true);

        await findSorting().vm.$emit('sortDirectionChange');

        expect(findSorting().props().isAscending).toBe(false);
      });

      it('emits an `update-sorting` event with the new direction', async () => {
        expect(wrapper.emitted('update-sorting')).toBeUndefined();

        await findSorting().vm.$emit('sortDirectionChange');
        await findSorting().vm.$emit('sortDirectionChange');

        expect(wrapper.emitted('update-sorting')).toEqual([
          [`${SORT_OPTION_POPULARITY}_${SORT_ASC}`],
          [`${SORT_OPTION_POPULARITY}_${SORT_DESC}`],
        ]);
      });
    });

    describe('when changing sort option', () => {
      it('changes the sort option to `Created date`', async () => {
        await findSorting().vm.$emit('sortByChange', SORT_OPTION_CREATED);

        expect(findSorting().props().sortBy).toBe(SORT_OPTION_CREATED);
        expect(findSorting().props().text).toBe('Created date');
      });

      it('changes the sort option to `Star count`', async () => {
        await findSorting().vm.$emit('sortByChange', SORT_OPTION_STAR_COUNT);

        expect(findSorting().props('sortBy')).toBe(SORT_OPTION_STAR_COUNT);
        expect(findSorting().props('text')).toBe('Star count');
      });
    });
  });
});
