import { shallowMount } from '@vue/test-utils';
import SearchAndSortBar from '~/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSortContainerRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

describe('SearchAndSortBar', () => {
  let wrapper;

  const defaultProps = {
    namespace: '42',
    searchInputPlaceholder: 'Search term',
  };

  const findFilteredSortContainerRoot = () => wrapper.findComponent(FilteredSortContainerRoot);

  const createComponent = (config) => {
    const { props = {}, listeners = {} } = config;

    wrapper = shallowMount(SearchAndSortBar, {
      propsData: { ...defaultProps, ...props },
      listeners,
    });
  };

  describe('onFilter', () => {
    const onFilter = jest.fn();

    beforeEach(() => {
      createComponent({
        listeners: { onFilter },
      });
    });

    it('parses and propagates emitted search event', () => {
      const filteredSortContainerRoot = findFilteredSortContainerRoot();
      filteredSortContainerRoot.vm.$emit('onFilter', [
        {
          id: 'token-1',
          type: FILTERED_SEARCH_TERM,
          value: {
            data: 'abc',
          },
        },
        {
          id: 'token-2',
          type: FILTERED_SEARCH_TERM,
          value: {
            data: 'def',
          },
        },
        {
          id: 'token-3',
          type: FILTERED_SEARCH_TERM,
          value: {
            data: '123',
          },
        },
      ]);

      expect(onFilter).toHaveBeenCalledTimes(1);
      expect(onFilter).toHaveBeenCalledWith('abc def 123');
    });
  });

  describe('onSort', () => {
    const onSort = jest.fn();

    beforeEach(() => {
      createComponent({
        listeners: { onSort },
      });
    });

    it('propagates emitted sorting value', () => {
      const SORTING_VALUE = 'name_desc';
      const filteredSortContainerRoot = findFilteredSortContainerRoot();
      filteredSortContainerRoot.vm.$emit('onSort', SORTING_VALUE);

      expect(onSort).toHaveBeenCalledTimes(1);
      expect(onSort).toHaveBeenCalledWith(SORTING_VALUE);
    });
  });
});
