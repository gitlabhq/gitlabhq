import { GlSorting, GlSortingItem, GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/vue_shared/components/registry/registry_search.vue';

describe('Registry Search', () => {
  let wrapper;

  const findPackageListSorting = () => wrapper.find(GlSorting);
  const findSortingItems = () => wrapper.findAll(GlSortingItem);
  const findFilteredSearch = () => wrapper.find(GlFilteredSearch);

  const defaultProps = {
    filter: [],
    sorting: { sort: 'asc', orderBy: 'name' },
    tokens: ['foo'],
    sortableFields: [{ label: 'name', orderBy: 'name' }, { label: 'baz' }],
  };

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSortingItem,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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
        availableTokens: wrapper.vm.tokens,
      });
    });

    it('emits filter:changed when value changes', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('input', 'foo');

      expect(wrapper.emitted('filter:changed')).toEqual([['foo']]);
    });

    it('emits filter:submit on submit event', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('submit');
      expect(wrapper.emitted('filter:submit')).toEqual([[]]);
    });

    it('emits filter:changed and filter:submit on clear event', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('clear');

      expect(wrapper.emitted('filter:changed')).toEqual([[[]]]);
      expect(wrapper.emitted('filter:submit')).toEqual([[]]);
    });

    it('binds tokens prop', () => {
      mountComponent();

      expect(findFilteredSearch().props('availableTokens')).toEqual(defaultProps.tokens);
    });
  });

  describe('sorting', () => {
    it('has all the sortable items', () => {
      mountComponent();

      expect(findSortingItems()).toHaveLength(defaultProps.sortableFields.length);
    });

    it('on sort change emits sorting:changed event', () => {
      mountComponent();

      findPackageListSorting().vm.$emit('sortDirectionChange');
      expect(wrapper.emitted('sorting:changed')).toEqual([[{ sort: 'desc' }]]);
    });

    it('on sort item click emits sorting:changed event ', () => {
      mountComponent();

      findSortingItems().at(0).vm.$emit('click');

      expect(wrapper.emitted('sorting:changed')).toEqual([
        [{ orderBy: defaultProps.sortableFields[0].orderBy }],
      ]);
    });
  });
});
