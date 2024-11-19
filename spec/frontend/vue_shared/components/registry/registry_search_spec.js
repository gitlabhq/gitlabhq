import { GlSorting, GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { markRaw } from '~/lib/utils/vue3compat/mark_raw';
import component from '~/vue_shared/components/registry/registry_search.vue';

describe('Registry Search', () => {
  let wrapper;

  const findPackageListSorting = () => wrapper.findComponent(GlSorting);
  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);

  const defaultProps = {
    filters: [],
    sorting: { sort: 'asc', orderBy: 'name' },
    tokens: [{ type: 'foo', token: markRaw({}) }],
    sortableFields: [
      { label: 'name', orderBy: 'name' },
      { label: 'baz', orderBy: 'bar' },
    ],
  };

  const defaultQueryChangedPayload = {
    foo: null,
    orderBy: 'name',
    search: null,
    sort: 'asc',
    after: null,
    before: null,
  };

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(component, {
      propsData,
    });
  };

  describe('searching', () => {
    it('has a filtered-search component', () => {
      mountComponent();

      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('binds the correct props to filtered-search', () => {
      mountComponent();

      expect(findFilteredSearch().props()).toMatchObject({
        value: [],
        placeholder: 'Filter results',
        termsAsTokens: true,
        searchTextOptionLabel: 'Search for this text',
        availableTokens: defaultProps.tokens,
      });
    });

    it('emits filter:changed when value changes', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('input', 'foo');

      expect(wrapper.emitted('filter:changed')).toEqual([['foo']]);
    });

    it('emits filter:submit and query:changed on submit event', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('submit');
      expect(wrapper.emitted('filter:submit')).toEqual([[]]);
      expect(wrapper.emitted('query:changed')).toEqual([[defaultQueryChangedPayload]]);
    });

    it('emits filter:changed, filter:submit and query:changed on clear event', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('clear');

      expect(wrapper.emitted('filter:changed')).toEqual([[[]]]);
      expect(wrapper.emitted('filter:submit')).toEqual([[]]);
      expect(wrapper.emitted('query:changed')).toEqual([[defaultQueryChangedPayload]]);
    });
  });

  describe('sorting', () => {
    it('has all the sortable items', () => {
      mountComponent();

      expect(findPackageListSorting().props().sortOptions).toMatchObject([
        { text: 'name', value: 'name' },
        { text: 'baz', value: 'bar' },
      ]);
    });

    it('on sort change emits sorting:changed event', () => {
      mountComponent();

      findPackageListSorting().vm.$emit('sortDirectionChange');
      expect(wrapper.emitted('sorting:changed')).toEqual([[{ sort: 'desc' }]]);
      expect(wrapper.emitted('query:changed')).toEqual([
        [{ ...defaultQueryChangedPayload, sort: 'desc' }],
      ]);
    });

    it('on sort item click emits sorting:changed event', () => {
      mountComponent();

      findPackageListSorting().vm.$emit('sortByChange', 'bar');

      expect(wrapper.emitted('sorting:changed')).toEqual([
        [{ orderBy: defaultProps.sortableFields[1].orderBy }],
      ]);
      expect(wrapper.emitted('query:changed')).toEqual([
        [{ ...defaultQueryChangedPayload, orderBy: 'bar' }],
      ]);
    });
  });

  describe('query string calculation', () => {
    const filters = [
      { type: FILTERED_SEARCH_TERM, value: { data: 'one' } },
      { type: FILTERED_SEARCH_TERM, value: { data: 'two' } },
      { type: 'typeOne', value: { data: 'value_one' } },
      { type: 'typeTwo', value: { data: 'value_two' } },
    ];

    it('aggregates the filter in the correct object', () => {
      mountComponent({ ...defaultProps, filters });

      findFilteredSearch().vm.$emit('submit');

      expect(wrapper.emitted('query:changed')).toEqual([
        [
          {
            ...defaultQueryChangedPayload,
            search: ['one', 'two'],
            typeOne: 'value_one',
            typeTwo: 'value_two',
          },
        ],
      ]);
    });
  });
});
